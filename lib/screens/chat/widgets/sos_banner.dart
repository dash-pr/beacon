import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/message_model.dart';

class SosBanner extends StatefulWidget {
  final MessageModel message;

  const SosBanner({super.key, required this.message});

  @override
  State<SosBanner> createState() => _SosBannerState();
}

class _SosBannerState extends State<SosBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  bool _vibrated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.7, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(SosBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.id != oldWidget.message.id) {
      _vibrated = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_vibrated) {
      _vibrated = true;
      HapticFeedback.heavyImpact();
    }

    final content = widget.message.content;
    final truncated =
        content.length > 60 ? '${content.substring(0, 60)}...' : content;

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.sosRed,
        child: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOS DETECTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${widget.message.senderName}: $truncated',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
