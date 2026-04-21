import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../models/doctor_assessment.dart';
import '../services/diagnosis_record_service.dart';
import '../services/google_cloud_speech_service.dart';
import '../services/google_cloud_tts_service.dart';
import '../services/openrouter_service.dart';
import '../theme/aura_theme.dart';
import '../widgets/doctor_call_stage.dart';

class HumanAiAssistantScreen extends StatefulWidget {
  const HumanAiAssistantScreen({super.key});

  @override
  State<HumanAiAssistantScreen> createState() => _HumanAiAssistantScreenState();
}

class _HumanAiAssistantScreenState extends State<HumanAiAssistantScreen> {
  static const String _openRouterApiKey =
      String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue:
        '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',
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
      'likelyConditions, redFlags, recommendedNextStep, confidence. Keep the '
      'spokenResponse natural and concise for speech. If a visible body part '
      'matters, set needsImage=true and ask for a clear photo of that area. '
      'Predict the most likely issue cautiously and name the most relevant '
      'specialist. If symptoms could be serious, mention urgent care and red '
      'flags clearly. Never claim certainty.';
  static const String _speechLanguageCode = 'en-IN';

  final OpenRouterChatService _chatService = OpenRouterChatService();
  final DiagnosisRecordService _diagnosisRecordService = DiagnosisRecordService();
  final GoogleCloudSpeechService _speechService = GoogleCloudSpeechService();
  final GoogleCloudTtsService _ttsService = GoogleCloudTtsService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _voiceRecorder = AudioRecorder();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final List<ChatMessage> _history = [
    ChatMessage.system(_systemPrompt),
  ];

  StreamSubscription<void>? _voiceCompleteSubscription;

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _isRecording = false;
  bool _isAnalyzingImage = false;
  bool _handsFreeMode = true;

  String _status = 'Preparing consultation...';
  String _lastUserText = '';
  String _lastAssistantText =
      'Hi, I am Sophia. Tell me what you are feeling and I will help you work through it.';
  DoctorAssessment? _latestAssessment;
  String? _imageRequestPrompt;
  String? _requestedBodyPart;
  String? _currentRecordingPath;
  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    unawaited(_initializeMicrophone());
    _voicePlayer.setReleaseMode(ReleaseMode.stop);
    _voiceCompleteSubscription = _voicePlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = false;
        _status = _handsFreeMode ? 'Listening...' : 'Ready';
      });
      if (_handsFreeMode && !_isListening && !_isThinking) {
        if (_latestAssessment?.hasImageRequest != true) {
          unawaited(_startListening(manual: false));
        }
      }
    });
  }

  @override
  void dispose() {
    unawaited(_voiceRecorder.stop());
    unawaited(_voicePlayer.stop());
    _voiceCompleteSubscription?.cancel();
    _chatService.dispose();
    _speechService.dispose();
    _ttsService.dispose();
    _diagnosisRecordService.dispose();
    super.dispose();
  }

  String _buildStructuredDiagnosisPrompt(String userText) {
    return '''
User symptom report:
$userText

Return strict JSON only using this schema:
{
  "spokenResponse": "short natural reply for voice playback",
  "diagnosisSummary": "detailed but cautious summary of the most likely issue",
  "targetSpecialty": "the most relevant doctor specialty, such as Dermatology, ENT, Ophthalmology, Orthopedics, General Medicine, etc.",
  "urgency": "routine | soon | urgent | emergency",
  "needsImage": true,
  "imageRequest": "tell the user exactly which body part to photograph",
  "bodyPart": "body part name like throat, skin, eye, foot, ear, etc.",
  "followUpQuestion": "one focused follow-up question",
  "likelyConditions": ["up to 3 likely possibilities"],
  "redFlags": ["short warning signs"],
  "recommendedNextStep": "what the user should do next",
  "confidence": 0.0
}

Rules:
- Keep spokenResponse empathetic and concise.
- If the user described a visible problem, set needsImage=true and ask for a clear photo in natural light.
- Be cautious and do not claim certainty.
- If serious symptoms are possible, set urgency to urgent or emergency and say so.
''';
  }

  Future<void> _initializeMicrophone() async {
    final available = await _voiceRecorder.hasPermission();

    if (!mounted) {
      return;
    }

    setState(() {
      _speechEnabled = available;
      _status = available
          ? (_openRouterApiKey.isEmpty
              ? 'Voice ready. Missing API key.'
              : 'Ready')
          : 'Microphone permission is required';
    });
  }

  Future<void> _toggleListening() async {
    if (_isThinking) {
      setState(() => _status = 'Doctor is thinking...');
      return;
    }

    if (_isSpeaking) {
      await _voicePlayer.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = false;
        _status = 'Speech interrupted';
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
      setState(() => _status = 'Microphone permission is required');
      return;
    }

    if (_isListening || _isRecording || _isThinking || _isSpeaking) {
      return;
    }

    final recordingPath = _buildRecordingPath();
    try {
      await _voiceRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: recordingPath,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isListening = false;
        _isRecording = false;
        _status = 'Unable to start recording';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = true;
      _isRecording = true;
      _currentRecordingPath = recordingPath;
      _status = manual ? 'Listening...' : 'Listening again...';
    });
  }

  Future<void> _stopListening({required bool userInitiated}) async {
    if (!_isListening && !_isRecording) {
      return;
    }

    final stoppedPath = await _voiceRecorder.stop();
    if (!mounted) {
      return;
    }

    final recordingPath = stoppedPath ?? _currentRecordingPath;
    _currentRecordingPath = null;

    setState(() {
      _isListening = false;
      _isRecording = false;
      _status = userInitiated ? 'Processing voice...' : 'Ready';
    });

    if (recordingPath != null && recordingPath.isNotEmpty) {
      unawaited(_handleRecordedUtterance(recordingPath));
    } else if (_handsFreeMode && !userInitiated) {
      unawaited(_startListening(manual: false));
    }
  }

  Future<void> _handleRecordedUtterance(String audioPath) async {
    try {
      final transcript = await _speechService.transcribeFile(
        audioPath: audioPath,
        languageCode: _speechLanguageCode,
      );

      try {
        await File(audioPath).delete();
      } catch (_) {
        // Ignore cleanup failures.
      }

      final cleanedTranscript = transcript.trim();
      if (cleanedTranscript.isEmpty) {
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
        _lastUserText = cleanedTranscript;
      });

      await _handleUserUtterance(cleanedTranscript);
    } catch (_) {
      try {
        await File(audioPath).delete();
      } catch (_) {
        // Ignore cleanup failures.
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isThinking = false;
        _status = 'Speech transcription failed';
        _lastAssistantText = 'I could not hear you clearly. Please try again.';
      });

      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    }
  }

  Future<void> _handleUserUtterance(String userText) async {
    if (_openRouterApiKey.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isThinking = false;
        _status = 'Missing OpenRouter API key';
        _lastAssistantText =
            'Please add OPENROUTER_API_KEY using --dart-define and restart the app.';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isThinking = true;
      _status = 'Doctor is thinking...';
      _lastAssistantText = '';
    });

    _history.add(ChatMessage.user(userText));
    _trimHistory();

    try {
      String response;
      try {
        final structuredPrompt = _buildStructuredDiagnosisPrompt(userText);
        final streamBuffer = StringBuffer();
        response = await _chatService.streamReply(
          apiKey: _openRouterApiKey,
          model: _openRouterModel,
          messages: [
            ..._history,
            ChatMessage.user(structuredPrompt),
          ],
          onDelta: (delta) {
            streamBuffer.write(delta);
            if (!mounted) {
              return;
            }
            setState(() {
              _status = 'Doctor is responding...';
              _lastAssistantText = streamBuffer.toString();
            });
          },
        );
      } catch (_) {
        response = await _chatService.reply(
          apiKey: _openRouterApiKey,
          model: _openRouterModel,
          messages: _history,
        );
      }

      if (!mounted) {
        return;
      }

      final assessment = DoctorAssessment.fromAssistantText(response);

      _history.add(ChatMessage.assistant(assessment.rawJson));
      _trimHistory();

      await _storeAssessment(
        userText: userText,
        assessment: assessment,
      );

      setState(() {
        _latestAssessment = assessment;
        _imageRequestPrompt = assessment.hasImageRequest ? assessment.imageRequest : null;
        _requestedBodyPart = assessment.bodyPart.isNotEmpty ? assessment.bodyPart : null;
        _isThinking = false;
        _lastAssistantText = assessment.spokenResponse;
        _status = assessment.hasImageRequest
            ? 'Need image of ${assessment.bodyPart.isNotEmpty ? assessment.bodyPart : 'the affected area'}'
            : 'Dr. Sophia replied';
      });

      unawaited(_speakAssistant(assessment.spokenResponse));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isThinking = false;
        _status = 'Assistant error';
        _lastAssistantText = 'I could not reach Sophia right now.';
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
  }) async {
    try {
      await _diagnosisRecordService.storeAssessment(
        sessionId: _sessionId,
        userText: userText,
        assessment: assessment,
        imageName: imageName,
        imageMimeType: imageMimeType,
        imageBytesLength: imageBytesLength,
      );
    } catch (_) {
      // Storage is best-effort; the live consultation should continue even if
      // the MongoDB backend is offline.
    }
  }

  Future<void> _captureRequestedImage() async {
    if (_latestAssessment == null || !_latestAssessment!.hasImageRequest) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
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

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzingImage = true;
      _status = 'Analyzing image...';
      _lastUserText = 'Photo uploaded for $bodyPart';
    });

    try {
      _history.add(ChatMessage.user(
        'The user uploaded a clear photo of $bodyPart. Use it to refine the diagnosis.',
      ));
      _trimHistory();

      final imagePrompt = '''
Use the attached body-part image together with the earlier symptom history to refine the diagnosis.
Reply as strict JSON only using the same schema as before.
Be more specific about the likely issue, the most relevant specialty, and whether the user should see a doctor soon.
If the image does not clearly show the issue, ask for a better photo and name the exact body part again.
''';

      final response = await _chatService.replyWithImage(
        apiKey: _openRouterApiKey,
        model: _openRouterModel,
        messages: _history,
        imageBytes: bytes,
        imageMimeType: mimeType,
        prompt: imagePrompt,
      );

      final assessment = DoctorAssessment.fromAssistantText(response);
      _history.add(ChatMessage.assistant(assessment.rawJson));
      _trimHistory();

      await _storeAssessment(
        userText: 'Image uploaded for $bodyPart',
        assessment: assessment,
        imageName: image.name,
        imageMimeType: mimeType,
        imageBytesLength: bytes.length,
      );

      if (!mounted) {
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

      unawaited(_speakAssistant(assessment.spokenResponse));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAnalyzingImage = false;
        _status = 'Image analysis failed';
        _lastAssistantText = 'I could not read that photo clearly. Please try another angle in brighter light.';
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

  Future<void> _speakAssistant(String response) async {
    if (response.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSpeaking = true;
      _status = 'Sophia is speaking...';
    });

    try {
      final audioBytes = await _ttsService.synthesize(text: response);
      await _voicePlayer.stop();
      await _voicePlayer.play(
        BytesSource(
          Uint8List.fromList(audioBytes),
          mimeType: 'audio/mpeg',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = false;
        _status = 'Voice output failed';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    }
  }

  void _trimHistory() {
    const int maxMessages = 10;
    if (_history.length <= maxMessages + 1) {
      return;
    }
    _history.removeRange(1, _history.length - maxMessages);
  }

  String _buildRecordingPath() {
    return '${Directory.systemTemp.path}${Platform.pathSeparator}sophia_${DateTime.now().millisecondsSinceEpoch}.pcm';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF071110),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Sophia',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Live consultation • $_status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                _StateBadge(
                  label: _isThinking
                      ? 'Thinking'
                      : _isAnalyzingImage
                          ? 'Analyzing'
                          : _isListening
                              ? 'Listening'
                              : _isSpeaking
                                  ? 'Speaking'
                                  : 'Ready',
                  color: _isThinking
                      ? const Color(0xFF8FA6FF)
                      : _isAnalyzingImage
                          ? const Color(0xFFF2C46D)
                          : _isListening
                              ? const Color(0xFF2DB67C)
                              : _isSpeaking
                                  ? AuraColors.warning
                                  : Colors.white54,
                ),
              ],
            ),
            const SizedBox(height: 14),
            DoctorCallStage(
              doctorName: 'Dr. Sophia',
              subtitle: 'Warm telehealth guidance in real time',
              status: _status,
              isListening: _isListening,
              isThinking: _isThinking,
              isSpeaking: _isSpeaking || _isAnalyzingImage,
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
                    Row(
                      children: [
                        _SmallPill(label: _latestAssessment!.specialtyLabel),
                        const SizedBox(width: 8),
                        _SmallPill(label: _latestAssessment!.urgencyLabel),
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
                    if (_latestAssessment!.likelyConditions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _latestAssessment!.likelyConditions
                            .map((condition) => _SmallPill(label: condition))
                            .toList(growable: false),
                      ),
                    ],
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
                            '• $flag',
                            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                    if (_latestAssessment!.recommendedNextStep.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Next step: ${_latestAssessment!.recommendedNextStep}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
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
                    color: AuraColors.primary.withValues(alpha: 0.24),
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
                      _imageRequestPrompt ?? 'Please capture the affected body part in clear light.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _captureRequestedImage,
                      style: FilledButton.styleFrom(
                        backgroundColor: AuraColors.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    background: AuraColors.primary.withValues(alpha: 0.20),
                    textColor: Colors.white,
                  ),
                ],
              ),
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
                  onChanged: (value) {
                    setState(() {
                      _handsFreeMode = value;
                    });
                  },
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
                          ? AuraColors.tertiary
                          : _isSpeaking || _isAnalyzingImage
                              ? AuraColors.warning
                              : AuraColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(
                      _isListening
                          ? Icons.stop_rounded
                          : _isSpeaking || _isAnalyzingImage
                              ? Icons.volume_off_rounded
                              : Icons.mic_rounded,
                    ),
                    label: Text(
                      _isListening
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

/*
*** End Patch

          Future<void> _storeAssessment({
            required String userText,
            required DoctorAssessment assessment,
            String? imageName,
            String? imageMimeType,
            int? imageBytesLength,
          }) async {
            try {
              await _diagnosisRecordService.storeAssessment(
                sessionId: _sessionId,
                userText: userText,
                assessment: assessment,
                imageName: imageName,
                imageMimeType: imageMimeType,
                imageBytesLength: imageBytesLength,
              );
            } catch (_) {
              // Storage is best-effort; the live consultation should continue even if
              // the MongoDB backend is offline.
            }
          }

          Future<void> _captureRequestedImage() async {
            if (_latestAssessment == null || !_latestAssessment!.hasImageRequest) {
              return;
            }

            final image = await _imagePicker.pickImage(
              source: ImageSource.camera,
              imageQuality: 85,
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

            if (!mounted) {
              return;
            }

            setState(() {
              _isAnalyzingImage = true;
              _status = 'Analyzing image...';
              _lastUserText = 'Photo uploaded for $bodyPart';
            });

            try {
              _history.add(ChatMessage.user('The user uploaded a clear photo of $bodyPart. Use it to refine the diagnosis.'));
              _trimHistory();

              final imagePrompt = '''
        Use the attached body-part image together with the earlier symptom history to refine the diagnosis.
        Reply as strict JSON only using the same schema as before.
        Be more specific about the likely issue, the most relevant specialty, and whether the user should see a doctor soon.
        If the image does not clearly show the issue, ask for a better photo and name the exact body part again.
        ''';

              final response = await _chatService.replyWithImage(
                apiKey: _openRouterApiKey,
                model: _openRouterModel,
                messages: _history,
                imageBytes: bytes,
                imageMimeType: mimeType,
                prompt: imagePrompt,
              );

              final assessment = DoctorAssessment.fromAssistantText(response);
              _history.add(ChatMessage.assistant(assessment.rawJson));
              _trimHistory();

              await _storeAssessment(
                userText: 'Image uploaded for $bodyPart',
                assessment: assessment,
                imageName: image.name,
                imageMimeType: mimeType,
                imageBytesLength: bytes.length,
              );

              if (!mounted) {
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

              unawaited(_speakAssistant(assessment.spokenResponse));
            } catch (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _isAnalyzingImage = false;
                _status = 'Image analysis failed';
                _lastAssistantText = 'I could not read that photo clearly. Please try another angle in brighter light.';
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
        _isThinking = false;
        _status = 'Assistant error';
        _lastAssistantText = 'I could not reach Sophia right now.';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    }
  }

  Future<void> _speakAssistant(String response) async {
    if (response.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSpeaking = true;
      _status = 'Sophia is speaking...';
    });

    try {
      final audioBytes = await _ttsService.synthesize(text: response);
      await _voicePlayer.stop();
      await _voicePlayer.play(
        BytesSource(
          Uint8List.fromList(audioBytes),
          mimeType: 'audio/mpeg',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = false;
        _status = 'Voice output failed';
      });
      if (_handsFreeMode) {
        unawaited(_startListening(manual: false));
      }
    }
  }

  void _trimHistory() {
    const int maxMessages = 10;
    if (_history.length <= maxMessages + 1) {
      return;
    }
    _history.removeRange(1, _history.length - maxMessages);
  }

  String _buildRecordingPath() {
    return '${Directory.systemTemp.path}${Platform.pathSeparator}sophia_${DateTime.now().millisecondsSinceEpoch}.pcm';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF071110),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Sophia',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Live consultation • $_status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                _StateBadge(
                  label: _isThinking
                      ? 'Thinking'
                      : _isListening
                          ? 'Listening'
                          : _isSpeaking
                              ? 'Speaking'
                              : 'Ready',
                  color: _isThinking
                      ? const Color(0xFF8FA6FF)
                      : _isListening
                          ? const Color(0xFF2DB67C)
                          : _isSpeaking
                              ? AuraColors.warning
                              : Colors.white54,
                ),
              ],
            ),
            const SizedBox(height: 14),
            DoctorCallStage(
              doctorName: 'Dr. Sophia',
              subtitle: 'Warm telehealth guidance in real time',
              status: _status,
              isListening: _isListening,
              isThinking: _isThinking,
              isSpeaking: _isSpeaking,
            ),
            const SizedBox(height: 12),
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
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    background: AuraColors.primary.withValues(alpha: 0.20),
                    textColor: Colors.white,
                  ),
                ],
              ),
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
                  onChanged: (value) {
                    setState(() {
                      _handsFreeMode = value;
                    });
                  },
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
                          ? AuraColors.tertiary
                          : _isSpeaking
                              ? AuraColors.warning
                              : AuraColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(
                      _isListening
                          ? Icons.stop_rounded
                          : _isSpeaking
                              ? Icons.volume_off_rounded
                              : Icons.mic_rounded,
                    ),
                    label: Text(
                      _isListening
                          ? 'Stop'
                          : _isSpeaking
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

*/

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
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

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
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
