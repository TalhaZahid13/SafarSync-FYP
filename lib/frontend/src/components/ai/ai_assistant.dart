import 'package:flutter/material.dart';
import 'dart:math';

class AIAssistantButton extends StatefulWidget {
  final VoidCallback onClick;
  const AIAssistantButton({super.key, required this.onClick});

  @override
  State<AIAssistantButton> createState() => _AIAssistantButtonState();
}

class _AIAssistantButtonState extends State<AIAssistantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 96,
      right: 96,
      child: ScaleTransition(
        scale: _floatAnimation,
        child: GestureDetector(
          onTap: widget.onClick,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.smart_toy, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}

// AI Message Model
class AIMessage {
  final String text;
  final bool isUser;
  final String timestamp;

  AIMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIAssistant extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  const AIAssistant({super.key, required this.isOpen, required this.onClose});

  @override
  State<AIAssistant> createState() => _AIAssistantState();
}

class _AIAssistantState extends State<AIAssistant> {
  List<AIMessage> messages = [];
  final TextEditingController _controller = TextEditingController();

  final List<String> quickSuggestions = [
    'Plan a weekend trip',
    'Best restaurants in Islamabad',
    'Northern areas itinerary',
    'Budget-friendly packages',
  ];

  @override
  void initState() {
    super.initState();
    messages.add(
      AIMessage(
        text:
            "Assalam-o-Alaikum! I'm your AI travel assistant. How can I help you plan your trip today?",
        isUser: false,
        timestamp:
            "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}",
      ),
    );
  }

  void handleSendMessage() {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      messages.add(
        AIMessage(
          text: input,
          isUser: true,
          timestamp:
              "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}",
        ),
      );
      _controller.clear();
    });

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      final responses = [
        'Great choice! Hunza Valley is beautiful this time of year.',
        'I recommend visiting Monal Restaurant for the best views!',
        'Leave early morning around 6 AM to avoid traffic.',
        'Based on your interests, try Fairy Meadows, Skardu, and K2 Base Camp.',
      ];
      final aiResponse = responses[Random().nextInt(responses.length)];

      setState(() {
        messages.add(
          AIMessage(
            text: aiResponse,
            isUser: false,
            timestamp:
                "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}",
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Positioned(
      bottom: 96,
      right: 24,
      child: Container(
        width: 380,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.smart_toy, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AI Travel Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Online • Ready to help',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.5),
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Row(
                      mainAxisAlignment: msg.isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: msg.isUser
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFDB913),
                                      Color(0xFF1B5A6E),
                                    ],
                                  )
                                : null,
                            color: msg.isUser ? null : Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!msg.isUser)
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: Color(0xFF1B5A6E),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI Assistant',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1B5A6E),
                                      ),
                                    ),
                                  ],
                                ),
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isUser
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.timestamp,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: msg.isUser
                                      ? Colors.white70
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Quick suggestions
            if (messages.length <= 2)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickSuggestions.map((suggestion) {
                    return GestureDetector(
                      onTap: () {
                        _controller.text = suggestion;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5A6E),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Input field
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: handleSendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
