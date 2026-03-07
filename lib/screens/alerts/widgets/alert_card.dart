import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool showTranslation;

  const AlertCard({
    super.key,
    required this.alert,
    required this.showTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _typeIcon,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.type.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _severityBadge,
              ],
            ),
            const SizedBox(height: 8),

            // Area
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  alert.affectedArea,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('HH:mm').format(alert.issuedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Original text (Japanese)
            Text(
              alert.originalText,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            // Translation
            if (showTranslation) ...[
              const Divider(height: 16, color: AppColors.surfaceLight),
              Row(
                children: [
                  Icon(Icons.translate, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  const Text(
                    'English Translation',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                alert.translatedText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget get _typeIcon {
    IconData icon;
    Color color;
    switch (alert.type) {
      case 'earthquake':
        icon = Icons.vibration;
        color = AppColors.sosRed;
      case 'tsunami':
        icon = Icons.tsunami;
        color = AppColors.accent;
      case 'flood':
        icon = Icons.water;
        color = AppColors.accentLight;
      case 'fire':
        icon = Icons.local_fire_department;
        color = AppColors.urgentOrange;
      default:
        icon = Icons.warning;
        color = AppColors.warningYellow;
    }
    return Icon(icon, color: color, size: 22);
  }

  Widget get _severityBadge {
    Color color;
    switch (alert.severity) {
      case 'extreme':
        color = AppColors.sosRed;
      case 'severe':
        color = AppColors.urgentOrange;
      case 'moderate':
        color = AppColors.warningYellow;
      default:
        color = AppColors.safeGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        alert.severity.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
