import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/cloud_image_reference.dart';
import '../models/doctor_assessment.dart';
import '../services/diagnosis_record_service.dart';
import '../services/google_cloud_tts_service.dart';
import '../services/openrouter_service.dart';

class HumanAiAssistantScreen extends StatefulWidget {
  const HumanAiAssistantScreen({super.key});

  @override
  State<HumanAiAssistantScreen> createState() => _HumanAiAssistantScreenState();
}

class _HumanAiAssistantScreenState extends State<HumanAiAssistantScreen> {
  static const String _openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );
  static const String _openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'openai/gpt-4o-mini',
  );

  static const String _systemPrompt =
      'You are Dr. Sophia, a warm, realistic telehealth doctor assistant for '
      'an Indian patient. Reply as strict JSON only, with no markdown or extra '
      'text. Use these keys: spokenResponse, diagnosisSummary, targetSpecialty, '
      'urgency, needsImage, imageRequest, bodyPart, followUpQuestion, '
      'likelyConditions, redFlags, recommendedNextStep, confidence.';

  static const Duration _speechToTextTimeout = Duration(seconds: 18);
  static const Duration _replyTimeout = Duration(seconds: 30);
  static const Duration _imageReplyTimeout = Duration(seconds: 45);
  static const Duration _ttsTimeout = Duration(seconds: 22);

  final OpenRouterChatService _chatService = OpenRouterChatService();
  final DiagnosisRecordService _diagnosisRecordService = DiagnosisRecordService();
  final GoogleCloudTtsService _ttsService = GoogleCloudTtsService();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final TextEditingController _symptomController = TextEditingController();
  final FocusNode _symptomFocusNode = FocusNode();
  final List<ChatMessage> _history = <ChatMessage>[
    ChatMessage.system(_systemPrompt),
  ];

  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  Timer? _autoStopListeningTimer;
  Timer? _speakingWatchdogTimer;

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _isAnalyzingImage = false;
  bool _handsFreeMode = true;

  bool _speechResultHandled = false;
  String _lastRecognizedWords = '';
  int _interactionToken = 0;
  int _speechToken = 0;

  String _status = 'Preparing consultation...';
  String _lastUserText = '';
  String _lastAssistantText =
      'Hi, I am Dr. Sophia. Tell me what you are feeling and I will help step by step.';
  DoctorAssessment? _latestAssessment;
  String? _imageRequestPrompt;
  String? _requestedBodyPart;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeMicrophone());
  }

  @override
  void dispose() {
    _autoStopListeningTimer?.cancel();
    _speakingWatchdogTimer?.cancel();
    unawaited(_speechToText.stop());
    unawaited(_ttsService.stop());
    _symptomController.dispose();
    _symptomFocusNode.dispose();
    _chatService.dispose();
    _diagnosisRecordService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _initializeMicrophone() async {
    final available = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _speechEnabled = available;
      _status = available ? 'Ready' : 'Microphone permission is required';
    });
  }

  Future<void> _toggleListening() async {
    if (_isThinking) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Doctor is thinking...';
      });
      return;
    }

    if (_isSpeaking || _isAnalyzingImage) {
      _interactionToken++;
      _speakingWatchdogTimer?.cancel();
      await _ttsService.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = false;
        _isAnalyzingImage = false;
        _status = 'Interrupted';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
      return;
    }

    if (_isListening) {
      await _stopListening(userInitiated: true);
      return;
    }

    await _startListening(manual: true);
  }

  Future<void> _startListening({required bool manual}) async {
    if (!_speechEnabled) {
      if (!mounted) {
        return;
      }
      setState(() {
        _handsFreeMode = false;
        _status = 'Speech unavailable. Type symptoms and tap Send.';
        _lastAssistantText = 'Speech unavailable. Type symptoms and tap Send.';
      });
      _symptomFocusNode.requestFocus();
      return;
    }

    if (_isListening || _isThinking || _isSpeaking || _isAnalyzingImage) {
      return;
    }

    _speechResultHandled = false;
    _lastRecognizedWords = '';

    final started = await _speechToText.listen(
      onResult: (result) {
        _lastRecognizedWords = result.recognizedWords;

        if (!result.finalResult) {
          return;
        }

        final transcript = _lastRecognizedWords.trim();
        if (transcript.isEmpty || _speechResultHandled) {
          return;
        }

        _speechResultHandled = true;
        unawaited(_processSpokenTranscript(transcript));
      },
      listenFor: _speechToTextTimeout,
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );

    if (!started) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Unable to start speech recognition';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = true;
      _status = manual ? 'Listening...' : 'Listening again...';
    });
    _scheduleAutoStopListening();
  }

  Future<void> _stopListening({required bool userInitiated}) async {
    if (!_isListening) {
      return;
    }

    _cancelAutoStopListening();

    try {
      await _speechToText.stop();
    } catch (_) {
      // Ignore stop errors and continue with the last transcript.
    }

    if (!mounted) {
      return;
    }

    final transcript = _lastRecognizedWords.trim();

    setState(() {
      _isListening = false;
      _status = userInitiated ? 'Processing voice...' : 'Ready';
    });

    if (transcript.isNotEmpty && !_speechResultHandled) {
      _speechResultHandled = true;
      unawaited(_processSpokenTranscript(transcript));
      return;
    }

    if (_handsFreeMode && !userInitiated) {
      unawaited(_startListening(manual: false));
    }
  }

  void _scheduleAutoStopListening() {
    _cancelAutoStopListening();
    _autoStopListeningTimer = Timer(const Duration(seconds: 6), () {
      if (_isListening) {
        unawaited(_stopListening(userInitiated: false));
      }
    });
  }

  void _cancelAutoStopListening() {
    _autoStopListeningTimer?.cancel();
    _autoStopListeningTimer = null;
  }

  Future<void> _submitTypedSymptom() async {
    final text = _symptomController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _symptomController.clear();
    _symptomFocusNode.unfocus();

    if (_isListening) {
      await _stopListening(userInitiated: true);
    }

    if (_isSpeaking) {
      _interactionToken++;
      await _ttsService.stop();
      _speakingWatchdogTimer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = false;
      });
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _lastUserText = text;
    });

    await _handleUserUtterance(text);
  }

  Future<void> _processSpokenTranscript(String transcript) async {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'I did not catch that';
        _lastAssistantText = 'Please say that again and I will answer right away.';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _lastUserText = cleaned;
    });

    await _handleUserUtterance(cleaned);
  }

  Future<void> _handleUserUtterance(String userText) async {
    final int interactionToken = ++_interactionToken;

    if (!mounted) {
      return;
    }

    setState(() {
      _isThinking = true;
      _status = 'Doctor is thinking...';
      _lastAssistantText = 'Dr. Sophia is preparing a reply...';
    });

    _history.add(ChatMessage.user(userText));
    _trimHistory();

    try {
      final response = await _chatService
          .reply(
            apiKey: _openRouterApiKey,
            model: _openRouterModel,
            messages: _history,
          )
          .timeout(_replyTimeout);

      if (!mounted || interactionToken != _interactionToken) {
        return;
      }

      final assessment = DoctorAssessment.fromAssistantText(response);
      _history.add(ChatMessage.assistant(assessment.rawJson));
      _trimHistory();

      unawaited(_storeAssessment(userText: userText, assessment: assessment));

      if (!mounted || interactionToken != _interactionToken) {
        return;
      }

      setState(() {
        _latestAssessment = assessment;
        _imageRequestPrompt = assessment.hasImageRequest ? assessment.imageRequest : null;
        _requestedBodyPart = assessment.bodyPart.isNotEmpty ? assessment.bodyPart : null;
        _isThinking = false;
        _lastAssistantText = assessment.spokenResponse;
        _status = assessment.hasImageRequest
            ? 'Need image of ${assessment.bodyPart.isNotEmpty ? assessment.bodyPart : 'affected area'}'
            : 'Ready';
      });

      final speechText = assessment.spokenResponse.trim().isNotEmpty
          ? assessment.spokenResponse
          : assessment.diagnosisSummary;
      unawaited(_speakAssistant(speechText, sourceToken: interactionToken));
    } on TimeoutException {
      if (!mounted || interactionToken != _interactionToken) {
        return;
      }
      setState(() {
        _isThinking = false;
        _status = 'Assistant request timed out';
        _lastAssistantText = 'The response took too long. Please try again.';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    } catch (_) {
      if (!mounted || interactionToken != _interactionToken) {
        return;
      }
      setState(() {
        _isThinking = false;
        _status = 'Assistant error';
        _lastAssistantText = 'I could not process that. Please try again.';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    }
  }

  Future<void> _storeAssessment({
    required String userText,
    required DoctorAssessment assessment,
    String? imageName,
    String? imageMimeType,
    int? imageBytesLength,
    CloudImageReference? imageReference,
  }) async {
    try {
      await _diagnosisRecordService.storeAssessment(
        sessionId: _sessionId,
        userText: userText,
        assessment: assessment,
        imageName: imageName,
        imageMimeType: imageMimeType,
        imageBytesLength: imageBytesLength,
        imageReference: imageReference,
      );
    } catch (_) {
      // Persisting records should never block the live consultation loop.
    }
  }

  Future<void> _captureRequestedImage() async {
    if (_latestAssessment == null || !_latestAssessment!.hasImageRequest) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Image capture cancelled';
      });
      return;
    }

    final bytes = await image.readAsBytes();
    final mimeType = _imageMimeTypeForPath(image.path);
    final bodyPart = _requestedBodyPart?.trim().isNotEmpty == true
        ? _requestedBodyPart!.trim()
        : 'the affected area';
    final int interactionToken = ++_interactionToken;

    final imageReference = CloudImageReference(
      bucket: 'inline',
      objectName: image.name,
      gcsUri: 'data:$mimeType;base64,${base64Encode(bytes)}',
      mediaLink: 'data:$mimeType;base64,${base64Encode(bytes)}',
      contentType: mimeType,
      uploadedAt: DateTime.now().toUtc(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzingImage = true;
      _status = 'Analyzing image...';
      _lastUserText = 'Photo uploaded for $bodyPart';
    });

    try {
      _history.add(
        ChatMessage.user(
          'The user uploaded a clear photo of $bodyPart. Use it to refine the diagnosis.',
        ),
      );
      _trimHistory();

      final response = await _chatService
          .replyWithImage(
            apiKey: _openRouterApiKey,
            model: _openRouterModel,
            messages: _history,
            imageBytes: bytes,
            imageMimeType: mimeType,
            prompt:
                'Use the attached body-part image together with earlier symptoms '
                'to refine diagnosis. Reply as strict JSON only.',
          )
          .timeout(_imageReplyTimeout);

      if (!mounted || interactionToken != _interactionToken) {
        return;
      }

      final assessment = DoctorAssessment.fromAssistantText(response);
      _history.add(ChatMessage.assistant(assessment.rawJson));
      _trimHistory();

      unawaited(
        _storeAssessment(
          userText: 'Image uploaded for $bodyPart',
          assessment: assessment,
          imageName: image.name,
          imageMimeType: mimeType,
          imageBytesLength: bytes.length,
          imageReference: imageReference,
        ),
      );

      if (!mounted || interactionToken != _interactionToken) {
        return;
      }

      setState(() {
        _latestAssessment = assessment;
        _imageRequestPrompt = assessment.hasImageRequest ? assessment.imageRequest : null;
        _requestedBodyPart = assessment.bodyPart.isNotEmpty ? assessment.bodyPart : null;
        _isAnalyzingImage = false;
        _isThinking = false;
        _lastAssistantText = assessment.spokenResponse;
        _status = assessment.hasImageRequest
            ? 'Need another image of ${assessment.bodyPart.isNotEmpty ? assessment.bodyPart : 'the affected area'}'
            : 'Image analyzed';
      });

      final speechText = assessment.spokenResponse.trim().isNotEmpty
          ? assessment.spokenResponse
          : assessment.diagnosisSummary;
      unawaited(_speakAssistant(speechText, sourceToken: interactionToken));
    } on TimeoutException {
      if (!mounted || interactionToken != _interactionToken) {
        return;
      }
      setState(() {
        _isAnalyzingImage = false;
        _status = 'Image analysis timed out';
        _lastAssistantText = 'Image processing took too long. Please try again.';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    } catch (_) {
      if (!mounted || interactionToken != _interactionToken) {
        return;
      }
      setState(() {
        _isAnalyzingImage = false;
        _status = 'Image analysis failed';
        _lastAssistantText =
            'I could not read that photo clearly. Please try another angle with better light.';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    }
  }

  String _imageMimeTypeForPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }
    return 'image/jpeg';
  }

  Future<void> _speakAssistant(String response, {int? sourceToken}) async {
    final text = response.trim();
    if (text.isEmpty) {
      return;
    }

    if (sourceToken != null && sourceToken != _interactionToken) {
      return;
    }

    final int speechToken = ++_speechToken;

    if (!mounted) {
      return;
    }

    setState(() {
      _isSpeaking = true;
      _status = 'Dr. Sophia is speaking...';
    });

    try {
      await _ttsService.speak(text: text).timeout(_ttsTimeout);

      if (!mounted || speechToken != _speechToken) {
        return;
      }

      _speakingWatchdogTimer?.cancel();
      final estimatedSeconds = ((text.length / 14).ceil()).clamp(8, 35);
      _speakingWatchdogTimer = Timer(Duration(seconds: estimatedSeconds), () {
        if (!mounted || speechToken != _speechToken || !_isSpeaking) {
          return;
        }
        if (sourceToken != null && sourceToken != _interactionToken) {
          return;
        }
        setState(() {
          _isSpeaking = false;
          _status = _handsFreeMode ? 'Listening...' : 'Ready';
        });
        if (_handsFreeMode && !_isListening && !_isThinking && !_isAnalyzingImage) {
          unawaited(_startListening(manual: false));
        }
      });
    } on TimeoutException {
      if (!mounted || speechToken != _speechToken) {
        return;
      }
      setState(() {
        _isSpeaking = false;
        _status = 'Voice output timed out';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    } catch (_) {
      if (!mounted || speechToken != _speechToken) {
        return;
      }
      setState(() {
        _isSpeaking = false;
        _status = _handsFreeMode ? 'Listening...' : 'Ready';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    }
  }

  void _trimHistory() {
    const int maxMessages = 12;
    if (_history.length <= maxMessages + 1) {
      return;
    }
    _history.removeRange(1, _history.length - maxMessages);
  }

  Color _statusColor() {
    if (_isThinking) {
      return const Color(0xFF8FA6FF);
    }
    if (_isAnalyzingImage) {
      return const Color(0xFFF2C46D);
    }
    if (_isListening) {
      return const Color(0xFF2DB67C);
    }
    if (_isSpeaking) {
      return const Color(0xFFFFA34A);
    }
    return const Color(0xFF8FA89F);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF071110),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071110),
        elevation: 0,
        title: const Text('Dr. Sophia'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _statusColor().withValues(alpha: 0.40)),
              ),
              child: Center(
                child: Text(
                  _isThinking
                      ? 'Thinking'
                      : _isAnalyzingImage
                          ? 'Analyzing'
                          : _isListening
                              ? 'Listening'
                              : _isSpeaking
                                  ? 'Speaking'
                                  : 'Ready',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101B1A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Text(
                'Live consultation: $_status',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_latestAssessment != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF101B1A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(_latestAssessment!.specialtyLabel),
                        _InfoPill(_latestAssessment!.urgencyLabel),
                        ..._latestAssessment!.likelyConditions.map(_InfoPill.new),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _latestAssessment!.displaySummary,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    if (_latestAssessment!.redFlags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Red flags',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._latestAssessment!.redFlags.map(
                        (flag) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '- $flag',
                            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (_latestAssessment != null) const SizedBox(height: 12),
            if (_latestAssessment?.hasImageRequest == true)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1A18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF5CC8A1).withValues(alpha: 0.40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need a photo',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _imageRequestPrompt ??
                          'Please capture the affected body part in clear light.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _captureRequestedImage,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Capture image'),
                    ),
                  ],
                ),
              ),
            if (_latestAssessment?.hasImageRequest == true) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101B1A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: TextField(
                controller: _symptomController,
                focusNode: _symptomFocusNode,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitTypedSymptom(),
                style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type symptoms here if you prefer text instead of voice',
                  hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _submitTypedSymptom,
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xFF5CC8A1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SpeechBubble(
              label: 'You',
              text: _lastUserText.isEmpty
                  ? 'Tap Talk and describe your symptoms naturally...'
                  : _lastUserText,
              background: Colors.white.withValues(alpha: 0.10),
              textColor: Colors.white,
            ),
            const SizedBox(height: 10),
            _SpeechBubble(
              label: 'Dr. Sophia',
              text: _lastAssistantText,
              background: const Color(0xFF5CC8A1).withValues(alpha: 0.20),
              textColor: Colors.white,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Hands-free doctor call',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _handsFreeMode,
                  onChanged: _speechEnabled
                      ? (value) {
                          setState(() {
                            _handsFreeMode = value;
                          });
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/diagnosis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded),
                    label: const Text('Assessment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _toggleListening,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isListening
                          ? const Color(0xFF2DB67C)
                          : _isSpeaking || _isAnalyzingImage
                              ? const Color(0xFFFFA34A)
                              : const Color(0xFF5CC8A1),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(
                      !_speechEnabled
                          ? Icons.keyboard_rounded
                          : _isListening
                              ? Icons.stop_rounded
                              : _isSpeaking || _isAnalyzingImage
                                  ? Icons.volume_off_rounded
                                  : Icons.mic_rounded,
                    ),
                    label: Text(
                      !_speechEnabled
                          ? 'Type'
                          : _isListening
                              ? 'Stop'
                              : _isSpeaking || _isAnalyzingImage
                                  ? 'Interrupt'
                                  : _isThinking
                                      ? 'Thinking'
                                      : 'Talk',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.label,
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String label;
  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
