import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/api_service.dart';

class GroupChatPage extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  io.Socket? _socket;
  bool _loading = true;
  bool _sending = false;
  int? _myUserId;
  String? _typingName;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myUserId = await ApiService.getMySqlUserId();
    await _fetchHistory();
    _connectSocket();
  }

  Future<void> _fetchHistory() async {
    final resp = await ApiService.getRequest(
      '/group-chat/${widget.groupId}/messages?limit=50',
    );
    if (mounted) {
      final msgs = resp['messages'];
      setState(() {
        if (msgs is List) {
          _messages.addAll(msgs.cast<Map<String, dynamic>>());
        }
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _connectSocket() {
    final socketUrl = ApiService.socketUrl;
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join:group-chat', widget.groupId);
    });

    _socket!.on('chat:message', (data) {
      if (!mounted) return;
      final msg = Map<String, dynamic>.from(data as Map);
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });

    _socket!.on('chat:deleted', (data) {
      if (!mounted) return;
      final deletedId = (data as Map)['message_id'] as int?;
      if (deletedId != null) {
        setState(() => _messages.removeWhere((m) => m['message_id'] == deletedId));
      }
    });

    _socket!.on('chat:typing', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      if (d['isTyping'] == true) {
        setState(() => _typingName = d['userName'] as String?);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _typingName = null);
        });
      } else {
        setState(() => _typingName = null);
      }
    });
  }

  void _onTyping(String _) {
    _socket?.emit('chat:typing', {
      'groupId': widget.groupId,
      'userId': _myUserId,
      'userName': 'You',
      'isTyping': true,
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    _socket?.emit('chat:typing', {
      'groupId': widget.groupId,
      'userId': _myUserId,
      'isTyping': false,
    });

    await ApiService.postRequest(
      '/group-chat/${widget.groupId}/messages',
      {'message': text},
    );

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _deleteMessage(Map<String, dynamic> msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteRequest('/group-chat/${widget.groupId}/messages/${msg['message_id']}');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket?.emit('leave:group-chat', widget.groupId);
    _socket?.dispose();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_typingName != null)
              Text('$_typingName is typing...', style: TextStyle(fontSize: 11, color: cs.primary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('No messages yet', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
                            const SizedBox(height: 4),
                            Text('Be the first to say something!', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _MessageBubble(
                          msg: _messages[i],
                          isMe: _messages[i]['user_id'] == _myUserId,
                          onLongPress: _messages[i]['user_id'] == _myUserId
                              ? () => _deleteMessage(_messages[i])
                              : null,
                        ),
                      ),
          ),
          _InputBar(
            controller: _msgCtrl,
            sending: _sending,
            onChanged: _onTyping,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final VoidCallback? onLongPress;

  const _MessageBubble({required this.msg, required this.isMe, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = msg['sender_name'] as String? ?? 'User';
    final text = msg['message'] as String? ?? '';
    final time = _formatTime(msg['created_at'] as String?);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
              Text(text, style: TextStyle(color: isMe ? cs.onPrimary : cs.onSurface)),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(fontSize: 10, color: (isMe ? cs.onPrimary : cs.onSurface).withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: cs.primary,
              child: sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                    )
                  : IconButton(
                      icon: Icon(Icons.send, color: cs.onPrimary, size: 18),
                      onPressed: onSend,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
