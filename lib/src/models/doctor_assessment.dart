import 'dart:convert';

class DoctorAssessment {
  const DoctorAssessment({
    required this.spokenResponse,
    required this.diagnosisSummary,
    required this.targetSpecialty,
    required this.urgency,
    required this.needsImage,
    required this.imageRequest,
    required this.followUpQuestion,
    required this.redFlags,
    required this.likelyConditions,
    required this.recommendedNextStep,
    required this.bodyPart,
    required this.confidence,
    required this.rawJson,
  });

  final String spokenResponse;
  final String diagnosisSummary;
  final String targetSpecialty;
  final String urgency;
  final bool needsImage;
  final String imageRequest;
  final String followUpQuestion;
  final List<String> redFlags;
  final List<String> likelyConditions;
  final String recommendedNextStep;
  final String bodyPart;
  final double confidence;
  final String rawJson;

  factory DoctorAssessment.fallback(String text) {
    return DoctorAssessment(
      spokenResponse: text,
      diagnosisSummary: text,
      targetSpecialty: 'General medicine',
      urgency: 'unknown',
      needsImage: false,
      imageRequest: '',
      followUpQuestion: '',
      redFlags: const [],
      likelyConditions: const [],
      recommendedNextStep: '',
      bodyPart: '',
      confidence: 0.45,
      rawJson: text,
    );
  }

  factory DoctorAssessment.fromAssistantText(String text) {
    final decoded = _extractJsonObject(text);
    if (decoded == null) {
      return DoctorAssessment.fallback(text);
    }

    final spokenResponse = _readString(decoded, ['spokenResponse', 'response', 'message']) ?? text;
    return DoctorAssessment(
      spokenResponse: spokenResponse,
      diagnosisSummary: _readString(decoded, ['diagnosisSummary', 'summary']) ?? spokenResponse,
      targetSpecialty: _readString(decoded, ['targetSpecialty', 'specialty']) ?? 'General medicine',
      urgency: _readString(decoded, ['urgency', 'priority']) ?? 'unknown',
      needsImage: _readBool(decoded, ['needsImage', 'requiresImage']) ?? false,
      imageRequest: _readString(decoded, ['imageRequest', 'imagePrompt']) ?? '',
      followUpQuestion: _readString(decoded, ['followUpQuestion', 'nextQuestion']) ?? '',
      redFlags: _readList(decoded, ['redFlags']),
      likelyConditions: _readList(decoded, ['likelyConditions', 'possibleCauses']),
      recommendedNextStep: _readString(decoded, ['recommendedNextStep', 'nextStep']) ?? '',
      bodyPart: _readString(decoded, ['bodyPart', 'imageBodyPart']) ?? '',
      confidence: _readDouble(decoded, ['confidence']) ?? 0.5,
      rawJson: const JsonEncoder.withIndent('  ').convert(decoded),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'spokenResponse': spokenResponse,
      'diagnosisSummary': diagnosisSummary,
      'targetSpecialty': targetSpecialty,
      'urgency': urgency,
      'needsImage': needsImage,
      'imageRequest': imageRequest,
      'followUpQuestion': followUpQuestion,
      'redFlags': redFlags,
      'likelyConditions': likelyConditions,
      'recommendedNextStep': recommendedNextStep,
      'bodyPart': bodyPart,
      'confidence': confidence,
      'rawJson': rawJson,
    };
  }

  String get displaySummary => diagnosisSummary.isNotEmpty ? diagnosisSummary : spokenResponse;

  String get specialtyLabel => targetSpecialty.isNotEmpty ? targetSpecialty : 'General medicine';

  String get urgencyLabel => urgency.isNotEmpty ? urgency : 'unknown';

  bool get hasImageRequest => needsImage && imageRequest.trim().isNotEmpty;

  static Map<String, dynamic>? _extractJsonObject(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return null;
    }

    final jsonText = trimmed.substring(start, end + 1);
    try {
      final decoded = jsonDecode(jsonText);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true') return true;
        if (lower == 'false') return false;
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static List<String> _readList(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
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
    }
    return const [];
  }
}
