import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/sync/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service = ConnectivityService();
  StreamSubscription? _subscription;

  ConnectionMode get mode => _service.currentMode;
  String get modeLabel => _service.modeLabel;
  String get modeDescription => _service.modeDescription;
  bool get isOnline => _service.isOnline;
  bool get isSatellite => _service.isSatellite;
  bool get isLowBandwidth => _service.isLowBandwidth;

  Future<void> start() async {
    await _service.start();
    _subscription = _service.onModeChanged.listen((_) {
      notifyListeners();
    });
  }

  void setBleMeshActive(bool active) {
    _service.setBleMeshActive(active);
    notifyListeners();
  }

  void toggleSatelliteMock() {
    _service.setSatelliteMockMode(!isSatellite);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
