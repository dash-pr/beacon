import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AssistantBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isStreaming;

  const AssistantBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.outline.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Beacon AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              text.isEmpty && isStreaming ? '...' : text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 24,
                  height: 8,
                  child: _TypingIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (1 - (value - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha((opacity * 255).toInt()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
