import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/ai/voice_service.dart';
import '../camera/camera_screen.dart';
import 'widgets/message_bubble.dart';
import 'widgets/sos_banner.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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

    messageProvider.sendTextMessage(text, meshProvider.service);
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

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Camera Triage'),
            backgroundColor: AppColors.surface,
          ),
          body: const CameraScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final messages = messageProvider.messages;
    final latestSos = messageProvider.latestSos;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        if (latestSos != null) SosBanner(message: latestSos),
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_searching,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Messages sent via BLE mesh will appear here',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
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
        // Listening indicator
        if (_isListening)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppColors.sosRed.withAlpha(30),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, size: 16, color: AppColors.sosRed),
                SizedBox(width: 8),
                Text(
                  'Listening... release to stop',
                  style: TextStyle(fontSize: 12, color: AppColors.sosRed),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.surfaceLight),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Camera button
                IconButton(
                  onPressed: _openCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 22),
                  color: AppColors.accent,
                  tooltip: 'Camera Triage',
                ),
                // Voice input button
                GestureDetector(
                  onLongPressStart: _voiceReady ? (_) => _startListening() : null,
                  onLongPressEnd: _voiceReady ? (_) => _stopListening() : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isListening ? AppColors.sosRed : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : (_voiceReady ? AppColors.accent : AppColors.textMuted),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
