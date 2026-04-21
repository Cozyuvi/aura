import '../models/cloud_image_reference.dart';
import '../models/doctor_assessment.dart';
import 'auth_service.dart';
import 'local_aura_store.dart';

class DiagnosisRecordService {
  DiagnosisRecordService();

  final AuthService _authService = AuthService.instance;

  Future<void> storeAssessment({
    required String sessionId,
    required String userText,
    required DoctorAssessment assessment,
    String? imageName,
    String? imageMimeType,
    int? imageBytesLength,
    CloudImageReference? imageReference,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null || userId.trim().isEmpty) {
      throw Exception('You are not signed in');
    }

    await LocalAuraStore.instance.addDiagnosisRecord(
      userId: userId,
      sessionId: sessionId,
      userText: userText,
      assessment: assessment,
      imageName: imageName,
      imageMimeType: imageMimeType,
      imageBytesLength: imageBytesLength,
      imageReference: imageReference?.toJson(),
    );
  }

  void dispose() {
    return;
  }
}
