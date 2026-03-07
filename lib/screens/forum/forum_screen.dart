import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/forum_provider.dart';
import '../../providers/locale_provider.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ResourceType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          color: AppColors.surface,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(null, 'All', Icons.grid_view, locale),
                    const SizedBox(width: 6),
                    _filterChip(ResourceType.foodWater, locale.t('food_water'), Icons.water_drop),
                    const SizedBox(width: 6),
                    _filterChip(ResourceType.shelter, locale.t('shelter'), Icons.home),
                    const SizedBox(width: 6),
                    _filterChip(ResourceType.medical, locale.t('medical'), Icons.medical_services),
                    const SizedBox(width: 6),
                    _filterChip(ResourceType.hazard, locale.t('hazard'), Icons.warning),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(text: locale.t('verified')),
                  Tab(text: locale.t('pending')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReportList(verified: true),
              _buildReportList(verified: false),
            ],
          ),
        ),
        // Report button
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showAddReportDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(locale.t('report_resource')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(ResourceType? type, String label, IconData icon, [LocaleProvider? locale]) {
    final selected = _filterType == type;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.textMuted),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (_) => setState(() => _filterType = type),
    );
  }

  Widget _buildReportList({required bool verified}) {
    final forum = context.watch<ForumProvider>();
    final locale = context.watch<LocaleProvider>();
    var reports = verified ? forum.verifiedReports : forum.pendingReports;

    if (_filterType != null) {
      reports = reports.where((r) => r.type == _filterType).toList();
    }

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              verified ? Icons.verified : Icons.pending_actions,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              verified ? 'No verified reports' : 'No pending reports',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return _ReportCard(
          report: reports[index],
          locale: locale,
          onApprove: () => forum.approveReport(reports[index].id),
          onUpvote: () => forum.upvoteReport(reports[index].id),
        );
      },
    );
  }

  void _showAddReportDialog(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    ResourceType selectedType = ResourceType.foodWater;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.t('report_resource'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              // Type selector
              Wrap(
                spacing: 8,
                children: ResourceType.values.map((type) {
                  final selected = selectedType == type;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(_typeLabel(type, locale)),
                    avatar: Icon(_typeIcon(type), size: 16),
                    onSelected: (_) => setDialogState(() => selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Title (e.g. "Water at Shinjuku Park")',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Description — what, where, how much, hours...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  hintText: 'Location name (optional)',
                  prefixIcon: Icon(Icons.location_on, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    context.read<ForumProvider>().addReport(
                      type: selectedType,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      locationName: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(locale.t('send')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(ResourceType type, LocaleProvider locale) {
    switch (type) {
      case ResourceType.foodWater: return locale.t('food_water');
      case ResourceType.shelter: return locale.t('shelter');
      case ResourceType.medical: return locale.t('medical');
      case ResourceType.hazard: return locale.t('hazard');
    }
  }

  IconData _typeIcon(ResourceType type) {
    switch (type) {
      case ResourceType.foodWater: return Icons.water_drop;
      case ResourceType.shelter: return Icons.home;
      case ResourceType.medical: return Icons.medical_services;
      case ResourceType.hazard: return Icons.warning;
    }
  }
}

class _ReportCard extends StatelessWidget {
  final ResourceReport report;
  final LocaleProvider locale;
  final VoidCallback onApprove;
  final VoidCallback onUpvote;

  const _ReportCard({
    required this.report,
    required this.locale,
    required this.onApprove,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _typeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon, size: 18, color: _typeColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (report.status == ReportStatus.verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.safeGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.safeGreen.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 12, color: AppColors.safeGreen),
                        const SizedBox(width: 4),
                        Text(
                          locale.t('verified'),
                          style: const TextStyle(fontSize: 10, color: AppColors.safeGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.urgentOrange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.urgentOrange.withAlpha(80)),
                    ),
                    child: Text(
                      locale.t('pending'),
                      style: const TextStyle(fontSize: 10, color: AppColors.urgentOrange, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              report.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Location
            if (report.locationName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    report.locationName!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Reporter & approver
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  report.reporterName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(width: 4),
                Text(
                  _timeAgo(report.reportedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            if (report.status == ReportStatus.verified && report.approverName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.verified_user, size: 14, color: AppColors.safeGreen),
                  const SizedBox(width: 4),
                  Text(
                    '${locale.t('approved_by')}: ${report.approverName} (${_roleName(report.approverRole)})',
                    style: const TextStyle(fontSize: 11, color: AppColors.safeGreen),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Actions
            Row(
              children: [
                // Upvote
                InkWell(
                  onTap: onUpvote,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${report.upvotes}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Approve button (for pending)
                if (report.status == ReportStatus.pending)
                  TextButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(locale.t('approve'), style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.safeGreen),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (report.type) {
      case ResourceType.foodWater: return AppColors.info;
      case ResourceType.shelter: return AppColors.safeGreen;
      case ResourceType.medical: return AppColors.urgentOrange;
      case ResourceType.hazard: return AppColors.sosRed;
    }
  }

  IconData get _typeIcon {
    switch (report.type) {
      case ResourceType.foodWater: return Icons.water_drop;
      case ResourceType.shelter: return Icons.home;
      case ResourceType.medical: return Icons.medical_services;
      case ResourceType.hazard: return Icons.warning;
    }
  }

  String _roleName(ApproverRole? role) {
    switch (role) {
      case ApproverRole.government: return 'Government';
      case ApproverRole.responder: return 'Responder';
      case ApproverRole.volunteer: return 'Volunteer';
      case ApproverRole.authority: return 'Authority';
      case null: return '';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
