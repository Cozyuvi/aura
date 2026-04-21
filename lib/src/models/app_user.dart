class AppUserProfile {
  const AppUserProfile({
    this.age,
    this.sex = '',
    this.weightKg,
    this.heightCm,
    this.bloodGroup = '',
    this.city = '',
    this.conditions = const <String>[],
    this.medications = const <String>[],
    this.photoDataUrl = '',
  });

  final int? age;
  final String sex;
  final double? weightKg;
  final double? heightCm;
  final String bloodGroup;
  final String city;
  final List<String> conditions;
  final List<String> medications;
  final String photoDataUrl;

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'sex': sex,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'bloodGroup': bloodGroup,
      'city': city,
      'conditions': conditions,
      'medications': medications,
      'photoDataUrl': photoDataUrl,
    };
  }

  factory AppUserProfile.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    return AppUserProfile(
      age: _asIntOrNull(data['age']),
      sex: _asString(data['sex']),
      weightKg: _asDoubleOrNull(data['weightKg']),
      heightCm: _asDoubleOrNull(data['heightCm']),
      bloodGroup: _asString(data['bloodGroup']),
      city: _asString(data['city']),
      conditions: _asStringList(data['conditions']),
      medications: _asStringList(data['medications']),
      photoDataUrl: _asString(data['photoDataUrl']),
    );
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static double? _asDoubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static String _asString(dynamic value) {
    return value is String ? value.trim() : '';
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profile,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final AppUserProfile profile;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    AppUserProfile? profile,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profile: profile ?? this.profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile': profile.toJson(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      profile: AppUserProfile.fromJson(json['profile'] as Map<String, dynamic>?),
    );
  }
}
