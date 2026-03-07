import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/responder_provider.dart';
import 'widgets/severity_breakdown.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/responder_map.dart';
import 'widgets/sos_feed_list.dart';

class ResponderDashboardScreen extends StatefulWidget {
  const ResponderDashboardScreen({super.key});

  @override
  State<ResponderDashboardScreen> createState() => _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends State<ResponderDashboardScreen> {
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResponderProvider>();
    final locale = context.watch<LocaleProvider>();
    final messages = provider.filteredMessages;
    final locationMessages = provider.messagesWithLocation;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceLight,
          child: Row(
            children: [
              const Icon(Icons.dashboard, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                locale.t('responder_dashboard'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showMap ? Icons.map : Icons.map_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _showMap = !_showMap),
                color: AppColors.accent,
                tooltip: locale.t('toggle_map'),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => provider.refresh(),
                color: AppColors.accent,
              ),
            ],
          ),
        ),

        // Severity breakdown
        SeverityBreakdown(
          sosCount: provider.sosCount,
          urgentCount: provider.urgentCount,
          totalCount: provider.totalCount,
        ),

        // Map with SOS pins + heatmap
        if (_showMap)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ResponderMap(messages: locationMessages),
          ),

        // Filters
        FilterChipsBar(
          activeFilter: provider.activeFilter,
          onFilterChanged: (filter) => provider.setFilter(filter),
        ),

        // SOS Feed
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    locale.t('no_matching'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              : SosFeedList(messages: messages),
        ),
      ],
    );
  }
}
