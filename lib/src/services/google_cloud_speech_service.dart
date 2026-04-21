import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleCloudSpeechService {
  GoogleCloudSpeechService({
    this.credentialsAssetPath = 'assets/secure/google_service_account.json',
  }) : _clientFuture = _createClient(credentialsAssetPath);

  final String credentialsAssetPath;
  final Future<AutoRefreshingAuthClient> _clientFuture;

  static const String _speechEndpoint =
      'https://speech.googleapis.com/v1/speech:recognize';
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  static Future<AutoRefreshingAuthClient> _createClient(
    String credentialsAssetPath,
  ) async {
    final rawJson = await rootBundle.loadString(credentialsAssetPath);
    final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(rawJson) as Map<String, dynamic>,
    );
    return clientViaServiceAccount(credentials, _scopes);
  }

  Future<String> transcribeFile({
    required String audioPath,
    String languageCode = 'en-IN',
    int sampleRateHertz = 16000,
  }) async {
    final file = File(audioPath);
    final audioBytes = await file.readAsBytes();
    final transcript = await transcribeBytes(
      audioBytes: audioBytes,
      languageCode: languageCode,
      sampleRateHertz: sampleRateHertz,
    );
    return transcript;
  }

  Future<String> transcribeBytes({
    required List<int> audioBytes,
    String languageCode = 'en-IN',
    int sampleRateHertz = 16000,
  }) async {
    if (audioBytes.isEmpty) {
      return '';
    }

    final client = await _clientFuture;
    final response = await client.post(
      Uri.parse(_speechEndpoint),
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': sampleRateHertz,
          'languageCode': languageCode,
          'enableAutomaticPunctuation': true,
          'model': 'latest_short',
        },
        'audio': {
          'content': base64Encode(audioBytes),
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Google Speech error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'];
    if (results is! List || results.isEmpty) {
      return '';
    }

    final transcriptBuffer = StringBuffer();
    for (final result in results) {
      if (result is! Map<String, dynamic>) {
        continue;
      }
      final alternatives = result['alternatives'];
      if (alternatives is! List || alternatives.isEmpty) {
        continue;
      }
      final firstAlternative = alternatives.first;
      if (firstAlternative is! Map<String, dynamic>) {
        continue;
      }
      final transcript = firstAlternative['transcript'];
      if (transcript is String && transcript.trim().isNotEmpty) {
        if (transcriptBuffer.isNotEmpty) {
          transcriptBuffer.write(' ');
        }
        transcriptBuffer.write(transcript.trim());
      }
    }

    return transcriptBuffer.toString().trim();
  }

  void dispose() {
    final client = _clientFuture;
    unawaited(client.then((value) => value.close()));
  }
}
