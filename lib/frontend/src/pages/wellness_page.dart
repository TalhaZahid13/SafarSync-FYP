import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  List<Map<String, String>> messages = [];
  TextEditingController messageController = TextEditingController();
  bool loading = false;

  final wellnessPrompts = [
    '😟 I\'m feeling anxious',
    '😰 Stressed about the trip',
    '😔 I feel unsafe',
    '😤 Overwhelmed',
    '😴 I can\'t sleep',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellness Support'),
        backgroundColor: Colors.purple[300],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '🌟 Your Wellness Companion',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 24),
                          Text('How are you feeling today?'),
                          SizedBox(height: 24),
                          ...wellnessPrompts.map(
                            (prompt) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[200],
                                ),
                                onPressed: () => _sendMessage(prompt),
                                child: Text(
                                  prompt,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.all(8),
                          padding: EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue[200]
                                : Colors.purple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['content'] ?? ''),
                        ),
                      );
                    },
                  ),
          ),
          if (loading)
            Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Share your feelings...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage([String? text]) async {
    final message = text ?? messageController.text;
    if (message.isEmpty) return;

    messageController.clear();

    setState(() {
      messages.add({'role': 'user', 'content': message});
      loading = true;
    });

    try {
      // Try backend wellness endpoint first (persists chat history server-side)
      final history = messages
          .where((m) => m['role'] != null && m['content'] != null)
          .toList();
      final resp = await ApiService.postRequest('/ai/wellness', {
        'message': message,
        'history': history,
      });

      if (resp['ai_response'] == null) {
        throw Exception(
          resp['message'] ?? resp['error'] ?? 'AI request failed',
        );
      }
      final reply = resp['ai_response'] as String;

      if (mounted) {
        setState(() {
          loading = false;
          messages.add({'role': 'assistant', 'content': reply});
        });
      }
    } catch (_) {
      // Last-resort fallback
      if (mounted) {
        setState(() {
          loading = false;
          messages.add({
            'role': 'assistant',
            'content':
                "I'm here to listen and support you. Remember, you're doing great! 💙\n\nTake a deep breath. You have the strength to handle this.",
          });
        });
      }
    }
  }
}
