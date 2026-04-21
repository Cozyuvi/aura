import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/doctor_assessment.dart';

class DiagnosisRecordService {
  DiagnosisRecordService({
    http.Client? client,
    String? backendBaseUrl,
  })  : _client = client ?? http.Client(),
        _backendBaseUrl = _normalizeBackendBaseUrl(
          backendBaseUrl ?? const String.fromEnvironment(
            'AURA_BACKEND_URL',
            defaultValue: '',
          ),
        );

  final http.Client _client;
  final String _backendBaseUrl;

  bool get isConfigured => _backendBaseUrl.isNotEmpty;

  static String _normalizeBackendBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    }

    if (kIsWeb) {
      return '';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return 'http://127.0.0.1:3000';
      case TargetPlatform.fuchsia:
        return '';
    }
  }

  Future<void> storeAssessment({
    required String sessionId,
    required String userText,
    required DoctorAssessment assessment,
    String? imageName,
    String? imageMimeType,
    int? imageBytesLength,
  }) async {
    if (!isConfigured) {
      return;
    }

    final uri = Uri.parse('$_backendBaseUrl/api/diagnosis-records');
    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'sessionId': sessionId,
        'userText': userText,
        'assessment': assessment.toJson(),
        'imageName': imageName,
        'imageMimeType': imageMimeType,
        'imageBytesLength': imageBytesLength,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Diagnosis record error ${response.statusCode}: ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}
