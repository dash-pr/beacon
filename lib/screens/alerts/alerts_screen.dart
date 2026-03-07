import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/alert_model.dart';
import '../../services/alerts/jalert_service.dart';
import 'widgets/alert_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final JAlertService _alertService = JAlertService();
  List<AlertModel> _alerts = [];
  bool _showTranslation = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = await _alertService.fetchAlerts();
    setState(() => _alerts = alerts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Language toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceLight,
          child: Row(
            children: [
              const Icon(Icons.warning_amber, size: 18, color: AppColors.urgentOrange),
              const SizedBox(width: 8),
              const Text(
                'Disaster Alerts (J-Alert)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() => _showTranslation = !_showTranslation);
                },
                icon: Text(
                  _showTranslation ? 'EN' : 'JA',
                  style: const TextStyle(fontSize: 12),
                ),
                label: Icon(Icons.translate, size: 16, color: AppColors.accent),
              ),
            ],
          ),
        ),
        Expanded(
          child: _alerts.isEmpty
              ? const Center(
                  child: Text(
                    'No alerts',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    return AlertCard(
                      alert: _alerts[index],
                      showTranslation: _showTranslation,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
