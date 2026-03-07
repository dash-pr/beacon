import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/locale_provider.dart';

class SeverityBreakdown extends StatelessWidget {
  final int sosCount;
  final int urgentCount;
  final int totalCount;

  const SeverityBreakdown({
    super.key,
    required this.sosCount,
    required this.urgentCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final normalCount = totalCount - sosCount - urgentCount;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _countBadge('SOS', sosCount, AppColors.sosRed),
          const SizedBox(width: 10),
          _countBadge(locale.t('urgent'), urgentCount, AppColors.urgentOrange),
          const SizedBox(width: 10),
          _countBadge(locale.t('normal'), normalCount < 0 ? 0 : normalCount, AppColors.textMuted),
          const SizedBox(width: 10),
          _countBadge(locale.t('total'), totalCount, AppColors.accent),
        ],
      ),
    );
  }

  Widget _countBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
