import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

enum ConnectionMode {
  offline,
  bleMeshOnly,
  wifi,
  cellular,
  satellite,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  static const _platform = MethodChannel('com.beacon.app/satellite');

  final Connectivity _connectivity = Connectivity();
  final _modeController = StreamController<ConnectionMode>.broadcast();
  StreamSubscription? _subscription;
  ConnectionMode _currentMode = ConnectionMode.offline;
  bool _bleMeshActive = false;
  bool _satelliteMockMode = false;
  Timer? _satellitePollTimer;

  ConnectionMode get currentMode => _currentMode;
  Stream<ConnectionMode> get onModeChanged => _modeController.stream;
  bool get isOnline => _currentMode != ConnectionMode.offline && _currentMode != ConnectionMode.bleMeshOnly;
  bool get isSatellite => _currentMode == ConnectionMode.satellite;
  bool get hasAnyConnection => _currentMode != ConnectionMode.offline;

  /// Bandwidth hint for satellite mode — keep payloads minimal
  bool get isLowBandwidth => _currentMode == ConnectionMode.satellite;

  void setBleMeshActive(bool active) {
    _bleMeshActive = active;
    _updateMode();
  }

  /// Toggle satellite mode (mock or real detection)
  void setSatelliteMockMode(bool enabled) {
    _satelliteMockMode = enabled;
    _updateMode();
  }

  Future<void> start() async {
    final result = await _connectivity.checkConnectivity();
    _processResult(result);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _processResult,
    );

    // Poll for real satellite mode every 5s on supported devices
    _satellitePollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkRealSatelliteMode(),
    );
  }

  /// Check Android NetworkCapabilities for satellite transport.
  /// NET_CAPABILITY_NOT_BANDWIDTH_CONSTRAINED (value 35) is defined in API 36.
  /// On devices with API < 35, this is a no-op.
  Future<void> _checkRealSatelliteMode() async {
    if (_satelliteMockMode) return; // mock takes priority

    try {
      final isSatellite = await _platform.invokeMethod<bool>('isSatelliteMode');
      if (isSatellite == true && _currentMode != ConnectionMode.satellite) {
        _currentMode = ConnectionMode.satellite;
        _modeController.add(_currentMode);
      } else if (isSatellite == false && _currentMode == ConnectionMode.satellite && !_satelliteMockMode) {
        // Re-evaluate based on normal connectivity
        final result = await _connectivity.checkConnectivity();
        _processResult(result);
      }
    } on PlatformException {
      // Platform channel not available (web, or method not implemented)
    } on MissingPluginException {
      // Expected on non-Android platforms
    }
  }

  void _processResult(ConnectivityResult result) {
    if (_satelliteMockMode) {
      _currentMode = ConnectionMode.satellite;
      _modeController.add(_currentMode);
      return;
    }

    if (result == ConnectivityResult.wifi) {
      _currentMode = ConnectionMode.wifi;
    } else if (result == ConnectivityResult.mobile) {
      _currentMode = ConnectionMode.cellular;
    } else if (_bleMeshActive) {
      _currentMode = ConnectionMode.bleMeshOnly;
    } else {
      _currentMode = ConnectionMode.offline;
    }
    _modeController.add(_currentMode);
  }

  void _updateMode() {
    if (_satelliteMockMode) {
      _currentMode = ConnectionMode.satellite;
    } else if (_currentMode == ConnectionMode.offline && _bleMeshActive) {
      _currentMode = ConnectionMode.bleMeshOnly;
    }
    _modeController.add(_currentMode);
  }

  String get modeLabel {
    switch (_currentMode) {
      case ConnectionMode.offline:
        return 'Offline';
      case ConnectionMode.bleMeshOnly:
        return 'BLE Mesh';
      case ConnectionMode.wifi:
        return 'WiFi';
      case ConnectionMode.cellular:
        return 'Cellular';
      case ConnectionMode.satellite:
        return 'Starlink';
    }
  }

  String get modeDescription {
    switch (_currentMode) {
      case ConnectionMode.offline:
        return 'No connection available';
      case ConnectionMode.bleMeshOnly:
        return 'P2P mesh only — messages relay between nearby devices';
      case ConnectionMode.wifi:
        return 'Full connectivity — cloud sync active';
      case ConnectionMode.cellular:
        return 'Cellular — cloud sync active';
      case ConnectionMode.satellite:
        return 'au Starlink Direct — low bandwidth satellite connection. Text messages only, images disabled.';
    }
  }

  void dispose() {
    _subscription?.cancel();
    _satellitePollTimer?.cancel();
    _modeController.close();
  }
}
