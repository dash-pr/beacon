import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/ai/voice_service.dart';
import 'widgets/message_bubble.dart';

class DmScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const DmScreen({super.key, required this.userId, required this.userName});

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  bool _voiceReady = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      await _voiceService.initialize();
      if (mounted) setState(() => _voiceReady = _voiceService.isAvailable);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final meshProvider = context.read<MeshProvider>();
    final messageProvider = context.read<MessageProvider>();
    messageProvider.sendTextMessage(
      text,
      meshProvider.service,
      recipientId: widget.userId,
    );
    _controller.clear();
    _scrollToBottom();
  }

  void _startListening() async {
    if (!_voiceReady) return;
    setState(() => _isListening = true);
    await _voiceService.startListening(
      onResult: (text) {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      },
    );
  }

  void _stopListening() async {
    await _voiceService.stopListening();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final messages = messageProvider.dmsWith(widget.userId);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Direct message',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Direct message with ${widget.userName}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Messages are sent via BLE mesh',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: messages[index]);
                    },
                  ),
          ),
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.primary.withAlpha(20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Listening...',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.outline.withAlpha(60)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  GestureDetector(
                    onLongPressStart: _voiceReady ? (_) => _startListening() : null,
                    onLongPressEnd: _voiceReady ? (_) => _stopListening() : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? AppColors.primary.withAlpha(40)
                            : AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? AppColors.primary
                            : (_voiceReady ? AppColors.textSecondary : AppColors.textMuted),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.userName}...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
