import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../main.dart' as app;
import '../../providers/connectivity_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/safety_check_provider.dart';
import '../../services/sync/connectivity_service.dart';
import '../alerts/alerts_screen.dart';
import '../assistant/assistant_screen.dart';
import '../chat/chat_screen.dart';
import '../forum/forum_screen.dart';
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
    const ForumScreen(),
    const AlertsScreen(),
    const ResponderDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final conn = context.watch<ConnectivityProvider>();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon'),
        actions: [
          // Language switcher
          PopupMenuButton<AppLanguage>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                locale.language.shortCode,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            onSelected: (lang) => locale.setLanguage(lang),
            itemBuilder: (_) => AppLanguage.values.map((lang) {
              final selected = locale.language == lang;
              return PopupMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.nativeName, style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    )),
                    const Spacer(),
                    if (selected)
                      const Icon(Icons.check, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.health_and_safety, size: 22),
            tooltip: locale.t('safety_check'),
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
          // Device count — tap for BLE debug log
          GestureDetector(
            onTap: () => _showBleDebug(context, mesh),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: mesh.connectedDeviceCount > 0
                        ? AppColors.safeGreen
                        : mesh.isRunning
                            ? Colors.orange
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
          ),
        ],
      ),
      body: Column(
        children: [
          const SafetyCheckBanner(),
          if (conn.isSatellite)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withAlpha(25),
                    const Color(0xFFFFA500).withAlpha(15),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFFFD700).withAlpha(40)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.satellite_alt, size: 16, color: Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.workspace_premium, size: 14, color: Color(0xFFFFD700)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locale.t('satellite_banner'),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: locale.t('chat'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: locale.t('assistant'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: locale.t('map'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum),
            label: locale.t('forum'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.warning_amber_outlined),
            selectedIcon: const Icon(Icons.warning_amber),
            label: locale.t('alerts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: locale.t('responder'),
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
        return AppColors.primary;
      case ConnectionMode.wifi:
        return AppColors.safeGreen;
      case ConnectionMode.cellular:
        return AppColors.safeGreen;
      case ConnectionMode.satellite:
        return const Color(0xFFFFD700);
    }
  }

  void _showBleDebug(BuildContext context, MeshProvider mesh) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bluetooth, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('BLE Mesh Debug', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const Spacer(),
                  Text(
                    mesh.connectedDeviceCount > 0 ? '${mesh.connectedDeviceCount} peer(s)' : 'No peers',
                    style: TextStyle(
                      fontSize: 12,
                      color: mesh.connectedDeviceCount > 0 ? AppColors.safeGreen : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusChip('Advertising', mesh.isAdvertising),
                  const SizedBox(width: 8),
                  _statusChip('Scanning', mesh.isScanning),
                  const SizedBox(width: 8),
                  _statusChip('Running', mesh.isRunning),
                ],
              ),
              const SizedBox(height: 8),
              Text('Device ID: ${app.deviceId.substring(0, 8)}...', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const Divider(),
              Expanded(
                child: mesh.debugLog.isEmpty
                    ? const Center(child: Text('No BLE events yet', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: mesh.debugLog.length,
                        itemBuilder: (_, i) {
                          final line = mesh.debugLog[mesh.debugLog.length - 1 - i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: line.contains('ERROR') || line.contains('error') || line.contains('WARNING')
                                    ? AppColors.sosRed
                                    : line.contains('READY') || line.contains('Connected')
                                        ? AppColors.safeGreen
                                        : AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.safeGreen.withAlpha(30) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? AppColors.safeGreen.withAlpha(80) : AppColors.outline.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: active ? AppColors.safeGreen : AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: active ? AppColors.safeGreen : AppColors.textMuted)),
        ],
      ),
    );
  }

  void _showConnectionInfo(BuildContext context, ConnectivityProvider conn) {
    final locale = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_connectionIcon(conn.mode), size: 24, color: _connectionColor(conn.mode)),
                const SizedBox(width: 12),
                Text(conn.modeLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(conn.modeDescription, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Row(
                children: [
                  const Text('au Starlink Direct', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, size: 10, color: Colors.black87),
                        SizedBox(width: 2),
                        Text('PRO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(locale.t('satellite_backup'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              value: conn.isSatellite,
              onChanged: (_) => conn.toggleSatelliteMock(),
            ),
            const SizedBox(height: 12),
            Text(locale.t('communication_layers'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
            const SizedBox(height: 8),
            _connectionLayer(Icons.bluetooth, locale.t('ble_mesh'), locale.t('ble_layer_desc')),
            _connectionLayer(Icons.satellite_alt, locale.t('starlink'), locale.t('satellite_layer_desc')),
            _connectionLayer(Icons.wifi, 'WiFi / ${locale.t('cellular')}', locale.t('wifi_layer_desc')),
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
          Icon(icon, size: 16, color: AppColors.primary),
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
