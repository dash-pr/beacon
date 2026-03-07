import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/permission_helper.dart';
import 'providers/connectivity_provider.dart';
import 'providers/llm_provider.dart';
import 'providers/message_provider.dart';
import 'providers/mesh_provider.dart';
import 'providers/responder_provider.dart';
import 'providers/safety_check_provider.dart';
import 'screens/home/home_screen.dart';

class BeaconApp extends StatefulWidget {
  const BeaconApp({super.key});

  @override
  State<BeaconApp> createState() => _BeaconAppState();
}

class _BeaconAppState extends State<BeaconApp> {
  final _meshProvider = MeshProvider();
  final _messageProvider = MessageProvider();
  final _safetyCheckProvider = SafetyCheckProvider();
  final _llmProvider = LlmProvider();
  final _responderProvider = ResponderProvider();
  final _connectivityProvider = ConnectivityProvider();

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _connectivityProvider.start();

    try {
      final granted = await PermissionHelper.requestBlePermissions();
      if (granted) {
        await _meshProvider.start();
        _messageProvider.init(_meshProvider.service);
        _connectivityProvider.setBleMeshActive(true);
      }
    } catch (_) {
      // BLE not available (e.g. web)
    }
    await _llmProvider.initialize();
  }

  @override
  void dispose() {
    _meshProvider.dispose();
    _messageProvider.dispose();
    _safetyCheckProvider.dispose();
    _llmProvider.dispose();
    _responderProvider.dispose();
    _connectivityProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _meshProvider),
        ChangeNotifierProvider.value(value: _messageProvider),
        ChangeNotifierProvider.value(value: _safetyCheckProvider),
        ChangeNotifierProvider.value(value: _llmProvider),
        ChangeNotifierProvider.value(value: _responderProvider),
        ChangeNotifierProvider.value(value: _connectivityProvider),
      ],
      child: MaterialApp(
        title: 'Beacon',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
