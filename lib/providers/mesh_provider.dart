import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/mesh/ble_mesh_service.dart';

class MeshProvider extends ChangeNotifier {
  final BleMeshService _meshService = BleMeshService();
  Timer? _statusTimer;

  int get connectedDeviceCount => _meshService.connectedDeviceCount;
  bool get isRunning => _meshService.isRunning;
  bool get isAdvertising => _meshService.isAdvertising;
  bool get isScanning => _meshService.isScanning;
  List<String> get debugLog => _meshService.debugLog;
  BleMeshService get service => _meshService;

  Future<void> start() async {
    await _meshService.start();
    // Poll connection count every 2 seconds
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> stop() async {
    _statusTimer?.cancel();
    await _meshService.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _meshService.dispose();
    super.dispose();
  }
}
