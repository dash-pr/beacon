import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/locale_provider.dart';

class FilterChipsBar extends StatelessWidget {
  final String activeFilter;
  final void Function(String) onFilterChanged;

  const FilterChipsBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    final filters = {
      'all': locale.t('all'),
      'sos': locale.t('sos_only'),
      'urgent': locale.t('urgent_plus'),
      'hasLocation': locale.t('has_location'),
      'last30': locale.t('last_30'),
    };

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: filters.entries.map((entry) {
          final isActive = activeFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
              selected: isActive,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceLight,
              checkmarkColor: Colors.white,
              onSelected: (_) => onFilterChanged(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
