import 'dart:typed_data';

import '../models/cloud_image_reference.dart';

class GoogleCloudStorageService {
  GoogleCloudStorageService({
    this.credentialsAssetPath = const String.fromEnvironment(
      'GOOGLE_SERVICE_ACCOUNT_JSON_PATH',
      defaultValue: '',
    ),
    this.bucketName = const String.fromEnvironment(
      'GOOGLE_CLOUD_STORAGE_BUCKET',
      defaultValue: '',
    ),
  });

  final String credentialsAssetPath;
  final String bucketName;

  Future<CloudImageReference> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    required String contentType,
    required String sessionId,
    String? bodyPart,
  }) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError.value(imageBytes, 'imageBytes', 'must not be empty');
    }

    final objectName = _buildObjectName(
      sessionId: sessionId,
      fileName: fileName,
      bodyPart: bodyPart,
    );

    final resolvedBucket = bucketName.trim().isNotEmpty ? bucketName.trim() : 'local';
    final localUri = 'local://$resolvedBucket/$objectName';

    return CloudImageReference(
      bucket: resolvedBucket,
      objectName: objectName,
      gcsUri: localUri,
      mediaLink: localUri,
      contentType: contentType,
      uploadedAt: DateTime.now().toUtc(),
    );
  }

  static String _buildObjectName({
    required String sessionId,
    required String fileName,
    String? bodyPart,
  }) {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final safeSessionId = _sanitizeComponent(sessionId, fallback: 'session');
    final safeBodyPart = bodyPart == null || bodyPart.trim().isEmpty
        ? 'photo'
        : _sanitizeComponent(bodyPart, fallback: 'photo');
    final safeFileName = _sanitizeFileName(fileName);
    return 'diagnosis-images/$safeSessionId/$timestamp-$safeBodyPart-$safeFileName';
  }

  static String _sanitizeComponent(String value, {required String fallback}) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-');
    final trimmed = sanitized.replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-');
    final trimmed = sanitized.replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');
    return trimmed.isEmpty ? 'image.jpg' : trimmed;
  }

  void dispose() {
    return;
  }
}