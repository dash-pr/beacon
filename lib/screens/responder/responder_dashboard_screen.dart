import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
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
              const Text(
                'Responder Dashboard',
                style: TextStyle(
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
                tooltip: 'Toggle map',
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

        // Map with SOS pins
        if (_showMap && locationMessages.isNotEmpty)
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
              ? const Center(
                  child: Text(
                    'No messages matching filter',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : SosFeedList(messages: messages),
        ),
      ],
    );
  }
}
