import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GROQ_CLIENT_KEY', defaultValue: '');

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.3-70b-versatile';

  static const String _systemPrompt =
      'You are Safar AI, a smart travel assistant for Pakistan built into the SafarSync app. '
      'You help users with trip planning, hotel and restaurant recommendations, routes, '
      'weather tips, cultural info, and budgeting for travel across Pakistan. '
      'Keep replies concise, friendly, and practical. '
      'If the user writes in Urdu or Roman Urdu, reply in the same language mix.';

  static const String _wellnessSystemPrompt =
      'You are SafarSync\'s wellness companion for travelers. '
      'You help with travel anxiety, jet lag, culture shock, loneliness, '
      'and maintaining mental and physical health while traveling. '
      'Be empathetic, supportive, and give actionable tips. '
      'Keep responses warm, brief, and practical.';

  /// Wellness chat — uses a dedicated empathetic system prompt.
  static Future<String> wellnessChat(
    String userMessage, {
    List<Map<String, String>> history = const [],
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _wellnessSystemPrompt},
      ...history.where((m) => m['role'] != null && m['content'] != null).cast<Map<String, String>>(),
      {'role': 'user', 'content': userMessage},
    ];
    return _callGroq(messages);
  }

  /// [history] entries use keys "role" ("user"/"assistant") and "content".
  static Future<String> chat(
    List<Map<String, String>> history,
    String userMessage,
  ) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ...history,
      {'role': 'user', 'content': userMessage},
    ];
    return _callGroq(messages);
  }

  static Future<String> _callGroq(List<Map<String, String>> messages) async {
    if (_apiKey.isEmpty) throw Exception('GROQ_CLIENT_KEY not configured');
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({'model': _model, 'messages': messages, 'temperature': 0.7, 'max_tokens': 512}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      return choices[0]['message']['content'] as String;
    } else {
      debugPrint('Groq error ${response.statusCode}: ${response.body}');
      Map<String, dynamic> errorBody = {};
      try {
        errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      final message =
          (errorBody['error'] as Map<String, dynamic>?)?['message']
              ?.toString() ??
          'HTTP ${response.statusCode}: ${response.body}';
      throw Exception(message);
    }
  }
}
