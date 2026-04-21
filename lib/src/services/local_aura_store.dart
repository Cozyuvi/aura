import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../models/client_dashboard_data.dart';
import '../models/doctor_assessment.dart';

class LocalAuraStore {
  LocalAuraStore._();

  static final LocalAuraStore instance = LocalAuraStore._();

  static const String _usersKey = 'aura_local_users_v1';
  static const String _recordsKey = 'aura_local_records_v1';
  static const String _sessionKey = 'aura_local_session_v1';
  static const int _maxRecords = 300;

  final Random _random = Random();

  Future<AuthSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null || sessionJson.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(sessionJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final rememberMe = decoded['rememberMe'] == true;
      final userId = (decoded['userId'] as String?)?.trim() ?? '';
      if (!rememberMe || userId.isEmpty) {
        return null;
      }

      final user = await _findUserById(userId);
      if (user == null) {
        return null;
      }

      return AuthSession(
        token: (decoded['token'] as String?)?.trim() ?? _generateToken(),
        expiresIn: (decoded['expiresIn'] as String?)?.trim() ?? 'local',
        rememberMe: rememberMe,
        user: user.toAppUser(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(AuthSession? session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session == null) {
      await prefs.remove(_sessionKey);
      return;
    }

    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'token': session.token,
        'expiresIn': session.expiresIn,
        'rememberMe': session.rememberMe,
        'userId': session.user.id,
      }),
    );
  }

  Future<AuthSession> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool rememberMe,
  }) async {
    final users = await _loadUsers();
    final normalizedEmail = _normalizeEmail(email);

    if (users.any((user) => user.email == normalizedEmail)) {
      throw Exception('An account with this email already exists');
    }

    final now = DateTime.now().toUtc();
    final salt = _generateId('salt');
    final passwordHash = _hashPassword(password, salt);
    final user = _StoredUser(
      id: _generateId('user'),
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      passwordHash: passwordHash,
      salt: salt,
      profile: const AppUserProfile(),
      createdAt: now,
      updatedAt: now,
    );

    users.add(user);
    await _saveUsers(users);

    final session = AuthSession(
      token: _generateToken(),
      expiresIn: 'local',
      rememberMe: rememberMe,
      user: user.toAppUser(),
    );
    await saveSession(rememberMe ? session : null);
    return session;
  }

  Future<AuthSession> loginUser({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final users = await _loadUsers();
    final normalizedEmail = _normalizeEmail(email);
    final user = users.where((entry) => entry.email == normalizedEmail).firstOrNull;

    if (user == null || !_verifyPassword(password, user.passwordHash, user.salt)) {
      throw Exception('Invalid email or password');
    }

    final session = AuthSession(
      token: _generateToken(),
      expiresIn: 'local',
      rememberMe: rememberMe,
      user: user.toAppUser(),
    );
    await saveSession(rememberMe ? session : null);
    return session;
  }

  Future<AppUser?> currentUser() async {
    final session = await restoreSession();
    return session?.user;
  }

  Future<AppUser> refreshUser(String userId) async {
    final user = await _findUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    return user.toAppUser();
  }

  Future<AppUser> updateUser({
    required String userId,
    required String name,
    required String phone,
    required AppUserProfile profile,
  }) async {
    final users = await _loadUsers();
    final index = users.indexWhere((user) => user.id == userId);
    if (index < 0) {
      throw Exception('User not found');
    }

    final current = users[index];
    final updated = current.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      profile: profile,
      updatedAt: DateTime.now().toUtc(),
    );
    users[index] = updated;
    await _saveUsers(users);
    return updated.toAppUser();
  }

  Future<void> logout() async {
    await saveSession(null);
  }

  Future<ClientDashboardData> buildDashboard(String userId) async {
    final user = await _findUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    final records = await _loadRecords();
    final userRecords = records
        .where((record) => record.userId == userId)
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final feedItems = userRecords
        .map((record) => record.toFeedItem())
        .toList(growable: false);

    final specialtySet = feedItems
        .map((record) => record.targetSpecialty.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final urgentCases = feedItems.where((record) {
      final urgency = record.urgency.trim().toLowerCase();
      return urgency == 'urgent' || urgency == 'emergency';
    }).length;

    return ClientDashboardData(
      user: user.toAppUser(),
      metrics: DashboardMetrics(
        sessions: feedItems.length,
        doctors: specialtySet.length,
        urgentCases: urgentCases,
      ),
      latestRecord: feedItems.isNotEmpty ? feedItems.first : null,
      recentRecords: feedItems,
    );
  }

  Future<void> addDiagnosisRecord({
    required String userId,
    required String sessionId,
    required String userText,
    required DoctorAssessment assessment,
    String? imageName,
    String? imageMimeType,
    int? imageBytesLength,
    Map<String, dynamic>? imageReference,
  }) async {
    final records = await _loadRecords();
    final record = _StoredDiagnosisRecord(
      id: _generateId('record'),
      userId: userId,
      sessionId: sessionId,
      userText: userText,
      assessment: assessment.toJson(),
      imageName: imageName?.trim() ?? '',
      imageMimeType: imageMimeType?.trim() ?? '',
      imageBytesLength: imageBytesLength ?? 0,
      imageReference: imageReference,
      createdAt: DateTime.now().toUtc(),
    );

    records.add(record);
    if (records.length > _maxRecords) {
      records.sort((left, right) => left.createdAt.compareTo(right.createdAt));
      final overflow = records.length - _maxRecords;
      if (overflow > 0) {
        records.removeRange(0, overflow);
      }
    }

    await _saveRecords(records);
  }

  Future<List<DiagnosisFeedItem>> recentRecordsForUser(String userId) async {
    final records = await _loadRecords();
    return records
        .where((record) => record.userId == userId)
        .map((record) => record.toFeedItem())
        .toList(growable: false)
      ..sort((left, right) => right.createdAt!.compareTo(left.createdAt!));
  }

  Future<_StoredUser?> _findUserById(String userId) async {
    final users = await _loadUsers();
    for (final user in users) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  Future<List<_StoredUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_usersKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return <_StoredUser>[];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        return <_StoredUser>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_StoredUser.fromJson)
          .toList(growable: false);
    } catch (_) {
      return <_StoredUser>[];
    }
  }

  Future<void> _saveUsers(List<_StoredUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((user) => user.toJson()).toList(growable: false)),
    );
  }

  Future<List<_StoredDiagnosisRecord>> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_recordsKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return <_StoredDiagnosisRecord>[];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        return <_StoredDiagnosisRecord>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_StoredDiagnosisRecord.fromJson)
          .toList(growable: false);
    } catch (_) {
      return <_StoredDiagnosisRecord>[];
    }
  }

  Future<void> _saveRecords(List<_StoredDiagnosisRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(records.map((record) => record.toJson()).toList(growable: false)),
    );
  }

  String _generateToken() {
    return 'local_${_generateId('token')}';
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = _random.nextInt(1 << 32).toRadixString(36);
    return '${prefix}_$timestamp$randomPart';
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt::$password')).toString();
  }

  bool _verifyPassword(String password, String hash, String salt) {
    return _hashPassword(password, salt) == hash;
  }
}

class _StoredUser {
  const _StoredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.salt,
    required this.profile,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final String salt;
  final AppUserProfile profile;
  final DateTime createdAt;
  final DateTime updatedAt;

  _StoredUser copyWith({
    String? name,
    String? phone,
    AppUserProfile? profile,
    DateTime? updatedAt,
  }) {
    return _StoredUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash,
      salt: salt,
      profile: profile ?? this.profile,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AppUser toAppUser() {
    return AppUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      profile: profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'passwordHash': passwordHash,
      'salt': salt,
      'profile': profile.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory _StoredUser.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;
    return _StoredUser(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      passwordHash: (json['passwordHash'] as String?)?.trim() ?? '',
      salt: (json['salt'] as String?)?.trim() ?? '',
      profile: AppUserProfile.fromJson(json['profile'] as Map<String, dynamic>?),
      createdAt: createdAtRaw != null ? DateTime.tryParse(createdAtRaw) ?? DateTime.now().toUtc() : DateTime.now().toUtc(),
      updatedAt: updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) ?? DateTime.now().toUtc() : DateTime.now().toUtc(),
    );
  }
}

class _StoredDiagnosisRecord {
  const _StoredDiagnosisRecord({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.userText,
    required this.assessment,
    required this.imageName,
    required this.imageMimeType,
    required this.imageBytesLength,
    required this.imageReference,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String sessionId;
  final String userText;
  final Map<String, dynamic> assessment;
  final String imageName;
  final String imageMimeType;
  final int imageBytesLength;
  final Map<String, dynamic>? imageReference;
  final DateTime createdAt;

  DiagnosisFeedItem toFeedItem() {
    return DiagnosisFeedItem.fromJson({
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'diagnosisSummary': assessment['diagnosisSummary'],
      'spokenResponse': assessment['spokenResponse'],
      'targetSpecialty': assessment['targetSpecialty'],
      'urgency': assessment['urgency'],
      'likelyConditions': assessment['likelyConditions'],
      'redFlags': assessment['redFlags'],
      'recommendedNextStep': assessment['recommendedNextStep'],
      'bodyPart': assessment['bodyPart'],
      'confidence': assessment['confidence'],
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'userText': userText,
      'assessment': assessment,
      'imageName': imageName,
      'imageMimeType': imageMimeType,
      'imageBytesLength': imageBytesLength,
      'imageReference': imageReference,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _StoredDiagnosisRecord.fromJson(Map<String, dynamic> json) {
    final assessment = json['assessment'];
    final createdAtRaw = json['createdAt'] as String?;
    return _StoredDiagnosisRecord(
      id: (json['id'] as String?)?.trim() ?? '',
      userId: (json['userId'] as String?)?.trim() ?? '',
      sessionId: (json['sessionId'] as String?)?.trim() ?? '',
      userText: (json['userText'] as String?)?.trim() ?? '',
      assessment: assessment is Map<String, dynamic> ? assessment : <String, dynamic>{},
      imageName: (json['imageName'] as String?)?.trim() ?? '',
      imageMimeType: (json['imageMimeType'] as String?)?.trim() ?? '',
      imageBytesLength: (json['imageBytesLength'] as num?)?.toInt() ?? 0,
      imageReference: json['imageReference'] is Map<String, dynamic>
          ? json['imageReference'] as Map<String, dynamic>
          : null,
      createdAt: createdAtRaw != null ? DateTime.tryParse(createdAtRaw) ?? DateTime.now().toUtc() : DateTime.now().toUtc(),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = moveNextIterator();
    if (iterator == null) {
      return null;
    }
    return iterator;
  }

  E? moveNextIterator() {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
