import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/safety_check_provider.dart';

class SafetyCheckBanner extends StatelessWidget {
  const SafetyCheckBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SafetyCheckProvider>();

    if (!provider.isActive && !provider.hasExpired) {
      return const SizedBox.shrink();
    }

    if (provider.hasExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.sosRed,
        child: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'AUTO-SOS SENT - Tap to cancel if safe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => provider.confirmSafe(),
              child: const Text(
                "I'm Safe",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final mins = provider.remaining.inMinutes;
    final secs = provider.remaining.inSeconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final isUrgent = provider.remaining.inSeconds < 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isUrgent ? AppColors.sosRed : AppColors.urgentOrange,
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Safety check: confirm safe within $timeStr',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => provider.confirmSafe(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text(
              "I'm Safe",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => provider.cancel(),
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}
