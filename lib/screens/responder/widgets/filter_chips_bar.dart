import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class FilterChipsBar extends StatelessWidget {
  final String activeFilter;
  final void Function(String) onFilterChanged;

  const FilterChipsBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const _filters = {
    'all': 'All',
    'sos': 'SOS Only',
    'urgent': 'Urgent+',
    'hasLocation': 'Has Location',
    'last30': 'Last 30 min',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _filters.entries.map((entry) {
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
