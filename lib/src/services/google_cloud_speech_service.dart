class GoogleCloudSpeechService {
  GoogleCloudSpeechService({
    this.credentialsAssetPath = const String.fromEnvironment(
      'GOOGLE_SERVICE_ACCOUNT_JSON_PATH',
      defaultValue: '',
    ),
  });

  final String credentialsAssetPath;

  Future<String> transcribeFile({
    required String audioPath,
    String languageCode = 'en-IN',
    int sampleRateHertz = 16000,
  }) async {
    return transcribeBytes(
      audioBytes: const <int>[],
      languageCode: languageCode,
      sampleRateHertz: sampleRateHertz,
    );
  }

  Future<String> transcribeBytes({
    required List<int> audioBytes,
    String languageCode = 'en-IN',
    int sampleRateHertz = 16000,
  }) async {
    return '';
  }

  void dispose() {
    return;
  }
}
