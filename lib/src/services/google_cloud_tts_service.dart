import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

class GoogleCloudTtsService {
  GoogleCloudTtsService({
    this.credentialsAssetPath = const String.fromEnvironment(
      'GOOGLE_SERVICE_ACCOUNT_JSON_PATH',
      defaultValue: '',
    ),
  }) : _flutterTts = FlutterTts();

  final String credentialsAssetPath;
  final FlutterTts _flutterTts;

  Future<void> _configureVoice(String languageCode) async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setSpeechRate(0.46);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  Future<List<int>> synthesize({
    required String text,
    String languageCode = 'en-IN',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const <int>[];
    }

    await _configureVoice(languageCode);
    await _flutterTts.speak(trimmed);
    return const <int>[];
  }

  Future<void> speak({
    required String text,
    String languageCode = 'en-IN',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _configureVoice(languageCode);
    await _flutterTts.speak(trimmed);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    unawaited(_flutterTts.stop());
  }
}
