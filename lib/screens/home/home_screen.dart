import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/safety_check_provider.dart';
import '../../services/sync/connectivity_service.dart';
import '../alerts/alerts_screen.dart';
import '../assistant/assistant_screen.dart';
import '../chat/chat_screen.dart';
import '../map/map_screen.dart';
import '../responder/responder_dashboard_screen.dart';
import 'widgets/safety_check_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const AssistantScreen(),
    const MapScreen(),
    const AlertsScreen(),
    const ResponderDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final conn = context.watch<ConnectivityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'Beacon',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety, size: 22),
            tooltip: 'Safety Check',
            onPressed: () {
              final safety = context.read<SafetyCheckProvider>();
              if (safety.isActive) {
                safety.confirmSafe();
              } else {
                safety.startCheck(reason: 'manual');
              }
            },
          ),
          // Connection mode indicator
          GestureDetector(
            onTap: () => _showConnectionInfo(context, conn),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _connectionColor(conn.mode).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _connectionColor(conn.mode).withAlpha(80),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _connectionIcon(conn.mode),
                    size: 14,
                    color: _connectionColor(conn.mode),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    conn.modeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: _connectionColor(conn.mode),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Device count
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: mesh.isRunning
                      ? AppColors.safeGreen
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${mesh.connectedDeviceCount}',
                  style: const TextStyle(fontSize: 13),
                ),
                const Icon(Icons.devices, size: 14),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SafetyCheckBanner(),
          // Satellite mode banner
          if (conn.isSatellite)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.accent.withAlpha(40),
              child: Row(
                children: [
                  const Icon(Icons.satellite_alt, size: 16, color: AppColors.accentLight),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Starlink Satellite — low bandwidth, text messages only',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => conn.toggleSatelliteMock(),
                    child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Responder',
          ),
        ],
      ),
    );
  }

  IconData _connectionIcon(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.offline:
        return Icons.signal_wifi_off;
      case ConnectionMode.bleMeshOnly:
        return Icons.bluetooth;
      case ConnectionMode.wifi:
        return Icons.wifi;
      case ConnectionMode.cellular:
        return Icons.signal_cellular_alt;
      case ConnectionMode.satellite:
        return Icons.satellite_alt;
    }
  }

  Color _connectionColor(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.offline:
        return AppColors.textMuted;
      case ConnectionMode.bleMeshOnly:
        return AppColors.accent;
      case ConnectionMode.wifi:
        return AppColors.safeGreen;
      case ConnectionMode.cellular:
        return AppColors.safeGreen;
      case ConnectionMode.satellite:
        return AppColors.warningYellow;
    }
  }

  void _showConnectionInfo(BuildContext context, ConnectivityProvider conn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _connectionIcon(conn.mode),
                  size: 24,
                  color: _connectionColor(conn.mode),
                ),
                const SizedBox(width: 12),
                Text(
                  conn.modeLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              conn.modeDescription,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // Satellite mock toggle for demo
            SwitchListTile(
              title: const Text(
                'Simulate Satellite Mode',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              subtitle: const Text(
                'Demo: simulate au Starlink Direct connection',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              value: conn.isSatellite,
              activeTrackColor: AppColors.warningYellow.withAlpha(100),
              onChanged: (_) => conn.toggleSatelliteMock(),
            ),
            const SizedBox(height: 12),
            // Connection layers info
            const Text(
              'Communication Layers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            _connectionLayer(Icons.bluetooth, 'BLE Mesh', 'P2P, ~50m range, relay via nearby devices'),
            _connectionLayer(Icons.satellite_alt, 'Starlink Satellite', 'Backup for mountains/remote areas'),
            _connectionLayer(Icons.wifi, 'WiFi / Cellular', 'Full cloud sync when available'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _connectionLayer(IconData icon, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
