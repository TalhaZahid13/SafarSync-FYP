import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class SafarAiChatPage extends StatefulWidget {
  const SafarAiChatPage({super.key});

  @override
  State<SafarAiChatPage> createState() => _SafarAiChatPageState();
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _SafarAiChatPageState extends State<SafarAiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text:
          'Assalam-o-Alaikum! Main Safar AI hoon. Trip planning, routes, hotels, aur food suggestions mein help kar sakta hoon.',
      isUser: false,
    ),
  ].toList();

  bool _isSending = false;

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true));
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    final response = await ApiService.sendAiMessage(input);
    final reply = response['success'] == true
        ? (response['response']?.toString() ?? 'No response from Safar AI.')
        : (response['message']?.toString() ?? 'Safar AI response failed.');

    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Safar AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: msg.isUser
                          ? LinearGradient(
                              colors: [
                                colorScheme.secondary,
                                colorScheme.primary,
                              ],
                            )
                          : null,
                      color: msg.isUser ? null : theme.cardColor,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser
                            ? colorScheme.onPrimary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask Safar AI...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSending ? null : _sendMessage,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
