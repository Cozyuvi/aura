class CloudImageReference {
  const CloudImageReference({
    required this.bucket,
    required this.objectName,
    required this.gcsUri,
    required this.mediaLink,
    required this.contentType,
    required this.uploadedAt,
  });

  final String bucket;
  final String objectName;
  final String gcsUri;
  final String mediaLink;
  final String contentType;
  final DateTime uploadedAt;

  Map<String, dynamic> toJson() {
    return {
      'bucket': bucket,
      'objectName': objectName,
      'gcsUri': gcsUri,
      'mediaLink': mediaLink,
      'contentType': contentType,
      'uploadedAt': uploadedAt.toUtc().toIso8601String(),
    };
  }

  factory CloudImageReference.fromJson(Map<String, dynamic> json) {
    final uploadedAtValue = json['uploadedAt'];
    final parsedUploadedAt = uploadedAtValue is String
        ? DateTime.tryParse(uploadedAtValue)
        : uploadedAtValue is DateTime
            ? uploadedAtValue
            : null;

    return CloudImageReference(
      bucket: (json['bucket'] as String?)?.trim() ?? '',
      objectName: (json['objectName'] as String?)?.trim() ?? '',
      gcsUri: (json['gcsUri'] as String?)?.trim() ?? '',
      mediaLink: (json['mediaLink'] as String?)?.trim() ?? '',
      contentType: (json['contentType'] as String?)?.trim() ?? '',
      uploadedAt: (parsedUploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc(),
    );
  }
}