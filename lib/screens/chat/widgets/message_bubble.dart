import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/message_model.dart';
import '../../../services/translation/translation_service.dart';
import '../../../main.dart' as app;

class MessageBubble extends StatefulWidget {
  final MessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  static final TranslationService _translationService = TranslationService();
  static bool _translationReady = false;
  String? _translatedText;
  bool _isTranslating = false;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _ensureTranslationReady();
  }

  Future<void> _ensureTranslationReady() async {
    if (!_translationReady) {
      try {
        await _translationService.initialize();
        _translationReady = true;
      } catch (_) {}
    }
  }

  Future<void> _translate() async {
    if (_translatedText != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }

    setState(() => _isTranslating = true);
    try {
      final result = await _translationService.translate(widget.message.content);
      setState(() {
        _translatedText = result;
        _showTranslation = true;
        _isTranslating = false;
      });
    } catch (_) {
      setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isOwn = message.senderId == app.deviceId;
    final isSos = message.priority == Priority.sos;
    final isUrgent = message.priority == Priority.urgent;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSos
              ? AppColors.messageSos
              : isOwn
                  ? AppColors.messageSent
                  : AppColors.messageReceived,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
          border: isSos
              ? Border.all(color: AppColors.sosRed, width: 1.5)
              : isUrgent
                  ? Border.all(color: AppColors.urgentOrange, width: 1)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwn)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSos ? AppColors.sosRed : AppColors.accentLight,
                ),
              ),
            if (!isOwn) const SizedBox(height: 2),
            if (isSos)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 14, color: AppColors.sosRed),
                    const SizedBox(width: 4),
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sosRed,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            // Translated text
            if (_showTranslation && _translatedText != null) ...[
              const Divider(height: 12, color: AppColors.textMuted),
              Text(
                _translatedText!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                if (message.hopCount > 0) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.repeat, size: 12, color: AppColors.textMuted),
                  Text(
                    '${message.hopCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // Translate button
                GestureDetector(
                  onTap: _isTranslating ? null : _translate,
                  child: _isTranslating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : Icon(
                          _showTranslation ? Icons.translate : Icons.translate,
                          size: 14,
                          color: _showTranslation
                              ? AppColors.accentLight
                              : AppColors.textMuted,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
