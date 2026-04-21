import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleCloudTtsService {
  GoogleCloudTtsService({
    this.credentialsAssetPath = 'assets/secure/google_service_account.json',
  }) : _clientFuture = _createClient(credentialsAssetPath);

  final String credentialsAssetPath;
  final Future<AutoRefreshingAuthClient> _clientFuture;

  static const String _ttsEndpoint =
      'https://texttospeech.googleapis.com/v1/text:synthesize';
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

  Future<List<int>> synthesize({
    required String text,
    String languageCode = 'en-IN',
  }) async {
    final client = await _clientFuture;
    final response = await client.post(
      Uri.parse(_ttsEndpoint),
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'input': {'text': text},
        'voice': {
          'languageCode': languageCode,
          'ssmlGender': 'FEMALE',
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'pitch': -2.0,
          'speakingRate': 0.94,
          'volumeGainDb': 0.0,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Google TTS error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final audioContent = data['audioContent'];
    if (audioContent is! String || audioContent.isEmpty) {
      throw Exception('Empty Google TTS response');
    }

    return base64Decode(audioContent);
  }

  void dispose() {
    final client = _clientFuture;
    unawaited(client.then((value) => value.close()));
  }
}
