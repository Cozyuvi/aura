import 'dart:convert';

import 'package:http/http.dart' as http;

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
  OpenRouterChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://aura.app',
        'X-Title': 'Aura Health Assistant',
      };

  Future<String> reply({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: _headers(apiKey),
      body: jsonEncode({
        'model': model,
        'messages': messages.map((message) => message.toJson()).toList(),
        'temperature': 0.4,
        'max_tokens': 320,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OpenRouter error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      final content = message?['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
    }

    throw Exception('Empty response from OpenRouter');
  }

  Future<String> streamReply({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    required void Function(String delta) onDelta,
  }) async {
    final request = http.Request('POST', Uri.parse(_endpoint))
      ..headers.addAll(_headers(apiKey))
      ..body = jsonEncode({
        'model': model,
        'messages': messages.map((message) => message.toJson()).toList(),
        'temperature': 0.4,
        'max_tokens': 320,
        'stream': true,
      });

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw Exception(
        'OpenRouter stream error ${streamedResponse.statusCode}: $errorBody',
      );
    }

    final buffer = StringBuffer();

    await for (final line in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) {
        continue;
      }

      final payload = line.substring(5).trim();
      if (payload.isEmpty) {
        continue;
      }
      if (payload == '[DONE]') {
        break;
      }

      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }

      final dynamic choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        continue;
      }

      final dynamic choice = choices.first;
      if (choice is! Map<String, dynamic>) {
        continue;
      }

      final dynamic delta = choice['delta'];
      if (delta is! Map<String, dynamic>) {
        continue;
      }

      final dynamic content = delta['content'];
      if (content is String && content.isNotEmpty) {
        buffer.write(content);
        onDelta(content);
      }
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      throw Exception('Empty stream response from OpenRouter');
    }
    return result;
  }

  void dispose() {
    _client.close();
  }
}
