import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/ai/voice_service.dart';

class VoiceInputButton extends StatefulWidget {
  final VoiceService voiceService;
  final void Function(String text) onResult;

  const VoiceInputButton({
    super.key,
    required this.voiceService,
    required this.onResult,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _isListening = false;

  void _startListening() async {
    setState(() => _isListening = true);
    await widget.voiceService.startListening(
      onResult: (text) {
        widget.onResult(text);
      },
    );
  }

  void _stopListening() async {
    await widget.voiceService.stopListening();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isListening ? AppColors.sosRed : AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening ? Colors.white : AppColors.accent,
          size: 22,
        ),
      ),
    );
  }
}
