import 'app_user.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.sessions,
    required this.doctors,
    required this.urgentCases,
  });

  final int sessions;
  final int doctors;
  final int urgentCases;

  factory DashboardMetrics.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    return DashboardMetrics(
      sessions: _asInt(data['sessions']),
      doctors: _asInt(data['doctors']),
      urgentCases: _asInt(data['urgentCases']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }
}

class DiagnosisFeedItem {
  const DiagnosisFeedItem({
    required this.id,
    required this.createdAt,
    required this.diagnosisSummary,
    required this.spokenResponse,
    required this.targetSpecialty,
    required this.urgency,
    required this.likelyConditions,
    required this.redFlags,
    required this.recommendedNextStep,
    required this.bodyPart,
    required this.confidence,
  });

  final String id;
  final DateTime? createdAt;
  final String diagnosisSummary;
  final String spokenResponse;
  final String targetSpecialty;
  final String urgency;
  final List<String> likelyConditions;
  final List<String> redFlags;
  final String recommendedNextStep;
  final String bodyPart;
  final double confidence;

  factory DiagnosisFeedItem.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final createdAt = createdAtRaw is String ? DateTime.tryParse(createdAtRaw) : null;
    return DiagnosisFeedItem(
      id: (json['id'] as String?)?.trim() ?? '',
      createdAt: createdAt,
      diagnosisSummary: (json['diagnosisSummary'] as String?)?.trim() ?? '',
      spokenResponse: (json['spokenResponse'] as String?)?.trim() ?? '',
      targetSpecialty: (json['targetSpecialty'] as String?)?.trim() ?? '',
      urgency: (json['urgency'] as String?)?.trim() ?? '',
      likelyConditions: _asStringList(json['likelyConditions']),
      redFlags: _asStringList(json['redFlags']),
      recommendedNextStep: (json['recommendedNextStep'] as String?)?.trim() ?? '',
      bodyPart: (json['bodyPart'] as String?)?.trim() ?? '',
      confidence: _asDouble(json['confidence']),
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0.0;
    }
    return 0.0;
  }
}

class ClientDashboardData {
  const ClientDashboardData({
    required this.user,
    required this.metrics,
    required this.latestRecord,
    required this.recentRecords,
  });

  final AppUser user;
  final DashboardMetrics metrics;
  final DiagnosisFeedItem? latestRecord;
  final List<DiagnosisFeedItem> recentRecords;

  factory ClientDashboardData.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recentRecords'];
    final recentRecords = recentRaw is List
        ? recentRaw
            .whereType<Map<String, dynamic>>()
            .map(DiagnosisFeedItem.fromJson)
            .toList(growable: false)
        : const <DiagnosisFeedItem>[];

    final latestRaw = json['latestRecord'];

    return ClientDashboardData(
      user: AppUser.fromJson((json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
      metrics: DashboardMetrics.fromJson(json['metrics'] as Map<String, dynamic>?),
      latestRecord:
          latestRaw is Map<String, dynamic> ? DiagnosisFeedItem.fromJson(latestRaw) : null,
      recentRecords: recentRecords,
    );
  }
}
