import 'dart:convert';

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => {
        'role': role,
        'content': content,
      };

  static ChatMessage system(String content) =>
      ChatMessage(role: 'system', content: content);
  static ChatMessage user(String content) =>
      ChatMessage(role: 'user', content: content);
  static ChatMessage assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);
}

class OpenRouterChatService {
  OpenRouterChatService();

  Future<String> reply({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async {
    return _buildAssessmentJson(
      messages: messages,
      imageProvided: false,
      prompt: '',
    );
  }

  Future<String> streamReply({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    required void Function(String delta) onDelta,
  }) async {
    final response = await reply(apiKey: apiKey, model: model, messages: messages);
    const int chunkSize = 28;
    for (var index = 0; index < response.length; index += chunkSize) {
      final end = index + chunkSize < response.length ? index + chunkSize : response.length;
      onDelta(response.substring(index, end));
    }
    return response;
  }

  Future<String> replyWithImage({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    required List<int> imageBytes,
    required String imageMimeType,
    required String prompt,
  }) async {
    return _buildAssessmentJson(
      messages: messages,
      imageProvided: imageBytes.isNotEmpty,
      prompt: prompt,
    );
  }

  void dispose() {
    return;
  }

  String _buildAssessmentJson({
    required List<ChatMessage> messages,
    required bool imageProvided,
    required String prompt,
  }) {
    final latestUserMessage = _latestUserMessage(messages);
    if (_isGreeting(latestUserMessage)) {
      return jsonEncode({
        'spokenResponse': 'Hello, I’m Dr. Sophia. Tell me what you’re feeling today and I’ll help you step by step.',
        'diagnosisSummary': 'Warm greeting and intake.',
        'targetSpecialty': 'General Medicine',
        'urgency': 'soon',
        'needsImage': false,
        'imageRequest': '',
        'bodyPart': '',
        'followUpQuestion': 'What symptoms are bothering you right now?',
        'likelyConditions': const <String>[],
        'redFlags': const <String>[],
        'recommendedNextStep': 'Describe the main symptom, how long it has been happening, and whether anything makes it better or worse.',
        'confidence': 0.72,
      });
    }

    if (_isFarewell(latestUserMessage)) {
      return jsonEncode({
        'spokenResponse': 'Take care. If anything gets worse or you want to continue, I’m here for you.',
        'diagnosisSummary': 'Friendly sign-off.',
        'targetSpecialty': 'General Medicine',
        'urgency': 'soon',
        'needsImage': false,
        'imageRequest': '',
        'bodyPart': '',
        'followUpQuestion': '',
        'likelyConditions': const <String>[],
        'redFlags': const <String>[],
        'recommendedNextStep': 'Come back if symptoms change or you need another opinion.',
        'confidence': 0.9,
      });
    }

    final context = _collectUserContext(messages);
    final lowerContext = _normalize('$context $prompt');
    final bodyPart = _inferBodyPart(messages, lowerContext);
    final specialty = _inferSpecialty(lowerContext, bodyPart);
    final urgency = _inferUrgency(lowerContext);
    final hasVisibleIssue = _isVisibleIssue(lowerContext, specialty, bodyPart);
    final needsImage = !imageProvided && hasVisibleIssue && urgency != 'emergency';
    final likelyConditions = _likelyConditions(lowerContext, specialty, bodyPart);
    final redFlags = _redFlags(lowerContext, urgency, specialty);
    final followUpQuestion = _followUpQuestion(specialty, bodyPart, urgency, lowerContext);
    final recommendedNextStep = _recommendedNextStep(urgency, specialty, needsImage);
    final diagnosisSummary = _diagnosisSummary(
      specialty: specialty,
      urgency: urgency,
      bodyPart: bodyPart,
      likelyConditions: likelyConditions,
      needsImage: needsImage,
    );
    final spokenResponse = _spokenResponse(
      specialty: specialty,
      urgency: urgency,
      bodyPart: bodyPart,
      followUpQuestion: followUpQuestion,
      needsImage: needsImage,
      summary: diagnosisSummary,
      recommendedNextStep: recommendedNextStep,
    );

    return jsonEncode({
      'spokenResponse': spokenResponse,
      'diagnosisSummary': diagnosisSummary,
      'targetSpecialty': specialty,
      'urgency': urgency,
      'needsImage': needsImage,
      'imageRequest': needsImage
          ? _imageRequestFor(bodyPart)
          : '',
      'bodyPart': bodyPart,
      'followUpQuestion': followUpQuestion,
      'likelyConditions': likelyConditions,
      'redFlags': redFlags,
      'recommendedNextStep': recommendedNextStep,
      'confidence': _confidenceFor(
        urgency == 'urgent' || urgency == 'emergency',
        specialty,
        imageProvided,
        hasVisibleIssue,
      ),
    });
  }

  String _collectUserContext(List<ChatMessage> messages) {
    final parts = <String>[];
    for (final message in messages) {
      if (message.role != 'user') {
        continue;
      }

      final content = message.content.trim();
      if (content.isEmpty || _looksLikePrompt(content)) {
        continue;
      }

      parts.add(content);
    }
    return parts.join(' ');
  }

  String _latestUserMessage(List<ChatMessage> messages) {
    for (final message in messages.reversed) {
      if (message.role != 'user') {
        continue;
      }

      final content = message.content.trim();
      if (content.isNotEmpty && !_looksLikePrompt(content)) {
        return content;
      }
    }
    return '';
  }

  bool _looksLikePrompt(String content) {
    final lower = content.toLowerCase();
    return lower.contains('return strict json only') ||
        lower.contains('reply as strict json only') ||
        lower.contains('use the attached body-part image') ||
        lower.contains('user symptom report:') ||
        lower.contains('the user uploaded a clear photo') ||
        lower.contains('you are dr. sophia') ||
        lower.contains('schema') ||
        lower.contains('keep the spokenresponse natural');
  }

  bool _isGreeting(String text) {
    final lower = _normalize(text);
    if (lower.isEmpty) {
      return false;
    }
    if (_containsMedicalContext(lower)) {
      return false;
    }
    return lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower.startsWith('hi ') ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ') ||
        lower.contains('good morning') ||
        lower.contains('good evening') ||
        lower.contains('good afternoon');
  }

  bool _isFarewell(String text) {
    final lower = _normalize(text);
    if (lower.isEmpty) {
      return false;
    }
    if (_containsMedicalContext(lower)) {
      return false;
    }
    return lower == 'bye' ||
        lower == 'goodbye' ||
        lower.contains('thank you') ||
        lower.contains('thanks') ||
        lower.contains('see you');
  }

  bool _containsMedicalContext(String text) {
    return _containsAny(text, [
      'pain',
      'fever',
      'cough',
      'cold',
      'headache',
      'head ache',
      'stomach',
      'abdomen',
      'chest',
      'breathing',
      'breath',
      'skin',
      'rash',
      'itch',
      'eye',
      'ear',
      'throat',
      'vomit',
      'nausea',
      'dizzy',
      'dizziness',
      'weakness',
      'swelling',
      'injury',
      'medicine',
      'tablet',
      'symptom',
    ]);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _inferBodyPart(List<ChatMessage> messages, String text) {
    final fromMessage = _extractBodyPartFromMessages(messages);
    if (fromMessage.isNotEmpty) {
      return fromMessage;
    }

    if (_containsAny(text, ['eye', 'vision', 'eyelid', 'red eye', 'blurred vision'])) {
      return 'eye';
    }
    if (_containsAny(text, ['throat', 'tonsil', 'sore throat', 'ear', 'sinus', 'nose', 'cough'])) {
      return 'throat';
    }
    if (_containsAny(text, ['skin', 'rash', 'itch', 'itching', 'hive', 'blister', 'eczema', 'acne', 'wound', 'burn', 'swelling', 'lump'])) {
      return 'skin';
    }
    if (_containsAny(text, ['chest', 'heart', 'breath', 'breathing', 'shortness of breath'])) {
      return 'chest';
    }
    if (_containsAny(text, ['stomach', 'abdomen', 'belly', 'nausea', 'vomit', 'diarrhea'])) {
      return 'abdomen';
    }
    if (_containsAny(text, ['headache', 'head', 'migraine', 'dizzy', 'dizziness'])) {
      return 'head';
    }
    if (_containsAny(text, ['knee', 'back', 'neck', 'joint', 'bone', 'fracture', 'sprain', 'shoulder'])) {
      return 'musculoskeletal area';
    }
    if (_containsAny(text, ['urine', 'urinary', 'burning urination', 'kidney', 'bladder'])) {
      return 'urinary tract';
    }
    if (_containsAny(text, ['period', 'menstrual', 'pregnant', 'pregnancy'])) {
      return 'lower abdomen';
    }
    return '';
  }

  String _extractBodyPartFromMessages(List<ChatMessage> messages) {
    final pattern = RegExp(r'photo of (.+?)(?:[.?!]|$)', caseSensitive: false);
    for (final message in messages.reversed) {
      if (message.role != 'user') {
        continue;
      }
      final match = pattern.firstMatch(message.content);
      if (match == null) {
        continue;
      }
      final extracted = match.group(1)?.trim() ?? '';
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }
    return '';
  }

  String _inferSpecialty(String text, String bodyPart) {
    if (_containsAny(text, ['chest pain', 'shortness of breath', 'palpitations', 'heart'])) {
      return 'Cardiology';
    }
    if (_containsAny(text, ['eye', 'vision', 'blurred vision', 'red eye'])) {
      return 'Ophthalmology';
    }
    if (_containsAny(text, ['ear', 'throat', 'tonsil', 'sinus', 'nose', 'cough', 'cold'])) {
      return 'ENT';
    }
    if (_containsAny(text, ['skin', 'rash', 'itch', 'eczema', 'acne', 'burn', 'wound', 'lump', 'blister'])) {
      return 'Dermatology';
    }
    if (_containsAny(text, ['stomach', 'abdomen', 'nausea', 'vomit', 'diarrhea', 'gastr', 'acid reflux'])) {
      return 'Gastroenterology';
    }
    if (_containsAny(text, ['knee', 'back', 'neck', 'joint', 'bone', 'sprain', 'fracture', 'shoulder'])) {
      return 'Orthopedics';
    }
    if (_containsAny(text, ['urine', 'urinary', 'kidney', 'bladder'])) {
      return 'Urology';
    }
    if (_containsAny(text, ['period', 'menstrual', 'pregnant', 'pregnancy'])) {
      return 'Gynecology';
    }
    if (_containsAny(text, ['headache', 'migraine', 'dizziness', 'seizure', 'numbness', 'weakness'])) {
      return 'Neurology';
    }
    if (_containsAny(text, ['anxiety', 'panic', 'depression', 'sleep', 'stress'])) {
      return 'Psychiatry';
    }
    if (bodyPart.isNotEmpty) {
      return bodyPart == 'eye'
          ? 'Ophthalmology'
          : bodyPart == 'skin'
              ? 'Dermatology'
              : 'General Medicine';
    }
    return 'General Medicine';
  }

  String _inferUrgency(String text) {
    if (_containsAny(text, [
      'chest pain',
      'severe chest',
      'difficulty breathing',
      'shortness of breath',
      'cannot breathe',
      'fainting',
      'passed out',
      'seizure',
      'stroke',
      'face droop',
      'slurred speech',
      'suicidal',
      'overdose',
      'poison',
      'vomiting blood',
      'severe bleeding',
      'loss of vision',
    ])) {
      return 'emergency';
    }

    if (_containsAny(text, [
      'severe',
      'worsening',
      'rapidly spreading',
      'high fever',
      'vision loss',
      'black stool',
      'blood in urine',
      'cannot walk',
      'severe pain',
      'swelling of face',
      'swelling of lips',
    ])) {
      return 'urgent';
    }

    if (_containsAny(text, ['for weeks', 'for months', 'chronic', 'persistent', 'ongoing'])) {
      return 'soon';
    }

    return 'soon';
  }

  bool _isVisibleIssue(String text, String specialty, String bodyPart) {
    return specialty == 'Dermatology' ||
        specialty == 'Ophthalmology' ||
        specialty == 'ENT' ||
        _containsAny(text, [
          'rash',
          'spot',
          'lump',
          'swelling',
          'bump',
          'bruise',
          'wound',
          'cut',
          'burn',
          'blister',
          'redness',
          'eye',
          'ear',
          'throat',
        ]) ||
        bodyPart.isNotEmpty;
  }

  List<String> _likelyConditions(String text, String specialty, String bodyPart) {
    if (specialty == 'Emergency Medicine') {
      return const [
        'Potential emergency condition',
        'Serious infection or circulation issue',
        'Acute pain syndrome',
      ];
    }

    if (specialty == 'Cardiology') {
      return const [
        'Heart-related chest pain',
        'Acid reflux',
        'Muscle strain',
      ];
    }

    if (specialty == 'Ophthalmology') {
      return const [
        'Eye irritation',
        'Conjunctivitis',
        'Dry eye or strain',
      ];
    }

    if (specialty == 'ENT') {
      return const [
        'Upper respiratory infection',
        'Sinus or throat inflammation',
        'Allergic irritation',
      ];
    }

    if (specialty == 'Dermatology') {
      return const [
        'Allergic rash',
        'Dermatitis',
        'Fungal or irritant skin reaction',
      ];
    }

    if (specialty == 'Gastroenterology') {
      return const [
        'Acid indigestion',
        'Gastroenteritis',
        'Food-related upset stomach',
      ];
    }

    if (specialty == 'Orthopedics') {
      return const [
        'Muscle strain',
        'Joint inflammation',
        'Soft tissue injury',
      ];
    }

    if (specialty == 'Neurology') {
      return const [
        'Tension headache',
        'Migraine',
        'Dizziness related to dehydration or illness',
      ];
    }

    if (specialty == 'Urology') {
      return const [
        'Urinary tract irritation',
        'Bladder infection',
        'Kidney-related discomfort',
      ];
    }

    if (specialty == 'Gynecology') {
      return const [
        'Hormonal or menstrual issue',
        'Pelvic discomfort',
        'Gynecologic irritation',
      ];
    }

    if (_containsAny(text, ['anxiety', 'panic', 'stress', 'sleep', 'depression'])) {
      return const [
        'Stress-related symptoms',
        'Anxiety',
        'Sleep disturbance',
      ];
    }

    if (bodyPart.isNotEmpty) {
      return [
        'Localized $bodyPart irritation',
        'Inflammation or strain',
        'Mild infection or allergy',
      ];
    }

    return const [
      'Minor infection or irritation',
      'Viral illness',
      'Stress-related symptoms',
    ];
  }

  List<String> _redFlags(String text, String urgency, String specialty) {
    if (urgency == 'emergency') {
      return const [
        'Call emergency services if symptoms worsen quickly.',
        'Do not delay if breathing, speech, or consciousness changes.',
      ];
    }

    final flags = <String>[
      'Get urgent care if the pain becomes severe or starts spreading.',
      'Seek help if you develop fever, fainting, or new weakness.',
    ];

    if (specialty == 'Ophthalmology') {
      flags.add('Seek urgent care for any sudden vision change or severe eye pain.');
    }
    if (specialty == 'Dermatology') {
      flags.add('Seek help for rapidly spreading redness, pus, or facial swelling.');
    }
    if (specialty == 'ENT') {
      flags.add('Seek urgent care if swallowing or breathing gets harder.');
    }

    return flags;
  }

  String _followUpQuestion(String specialty, String bodyPart, String urgency, String text) {
    if (urgency == 'emergency') {
      return 'Are you having chest pain, trouble breathing, fainting, or one-sided weakness right now?';
    }

    if (specialty == 'Dermatology') {
      return bodyPart.isNotEmpty
          ? 'How long has the $bodyPart issue been present, and is it itchy, painful, or spreading?'
          : 'How long has the rash or skin problem been present, and is it itchy or painful?';
    }

    if (specialty == 'Ophthalmology') {
      return 'Is your vision blurred, is there eye pain, redness, or discharge?';
    }

    if (specialty == 'ENT') {
      return 'Is there fever, difficulty swallowing, ear pain, or blocked breathing through the nose?';
    }

    if (specialty == 'Gastroenterology') {
      return 'Are you having vomiting, diarrhea, fever, or pain after meals?';
    }

    if (specialty == 'Orthopedics') {
      return 'Did the pain start after an injury, twist, or fall, and can you bear weight?';
    }

    if (specialty == 'Neurology') {
      return 'Do you have numbness, weakness, vomiting, or sensitivity to light?';
    }

    if (specialty == 'Urology') {
      return 'Do you have burning urination, fever, flank pain, or blood in the urine?';
    }

    if (specialty == 'Gynecology') {
      return 'Is the pain linked to your cycle, and is there any unusual discharge or bleeding?';
    }

    if (_containsAny(text, ['anxiety', 'panic', 'stress', 'sleep', 'depression'])) {
      return 'How long have you been feeling this way, and is it affecting sleep or daily work?';
    }

    return 'How long have you had this problem, and is it getting better or worse?';
  }

  String _recommendedNextStep(String urgency, String specialty, bool needsImage) {
    if (urgency == 'emergency') {
      return 'Go to the nearest emergency department now or call local emergency services.';
    }

    if (needsImage) {
      return 'Send a clear photo in bright natural light so the issue can be assessed more accurately.';
    }

    if (urgency == 'urgent') {
      return 'Arrange urgent in-person care today or within 24 hours.';
    }

    if (specialty == 'Dermatology' || specialty == 'Ophthalmology' || specialty == 'ENT') {
      return 'Book a focused specialist visit if the symptoms do not improve soon.';
    }

    return 'Monitor symptoms, rest, stay hydrated, and book a clinic visit if it is not improving.';
  }

  String _diagnosisSummary({
    required String specialty,
    required String urgency,
    required String bodyPart,
    required List<String> likelyConditions,
    required bool needsImage,
  }) {
    final areaText = bodyPart.isNotEmpty ? ' in the $bodyPart' : '';
    final leadCondition = likelyConditions.isNotEmpty ? likelyConditions.first : 'a mild health issue';

    if (urgency == 'emergency') {
      return 'The symptoms may represent a serious emergency$areaText. Immediate medical evaluation is recommended.';
    }

    if (needsImage) {
      return 'The symptoms suggest a visible issue$areaText such as $leadCondition, and a clear photo would help narrow it down.';
    }

    return 'This looks most consistent with $leadCondition$areaText. The most relevant specialty is $specialty.';
  }

  String _spokenResponse({
    required String specialty,
    required String urgency,
    required String bodyPart,
    required bool needsImage,
    required String followUpQuestion,
    required String summary,
    required String recommendedNextStep,
  }) {
    if (urgency == 'emergency') {
      return 'This could be serious. Please seek emergency care now.';
    }

    if (needsImage) {
      return 'I’m with you. I think this may need a clearer photo of the ${bodyPart.isNotEmpty ? bodyPart : 'affected area'}. Please send one in good light.';
    }

    final leadIn = specialty == 'General Medicine'
        ? 'Alright, let’s go through this together.'
        : 'Alright, let’s go through this together from a $specialty point of view.';
    final followUp = followUpQuestion.trim();
    if (followUp.isNotEmpty) {
      return '$leadIn $summary $recommendedNextStep $followUp';
    }
    return '$leadIn $summary $recommendedNextStep';
  }

  String _imageRequestFor(String bodyPart) {
    if (bodyPart.isNotEmpty) {
      return 'Please send a clear photo of the $bodyPart in bright natural light.';
    }
    return 'Please send a clear photo of the affected area in bright natural light.';
  }

  double _confidenceFor(bool urgencyHigh, String specialty, bool imageProvided, bool visibleIssue) {
    var confidence = 0.52;
    if (specialty != 'General Medicine') {
      confidence += 0.08;
    }
    if (imageProvided) {
      confidence += 0.08;
    }
    if (visibleIssue) {
      confidence += 0.05;
    }
    if (urgencyHigh) {
      confidence += 0.10;
    }
    if (confidence > 0.92) {
      confidence = 0.92;
    }
    return double.parse(confidence.toStringAsFixed(2));
  }

  bool _containsAny(String text, List<String> phrases) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }
    return false;
  }
}
