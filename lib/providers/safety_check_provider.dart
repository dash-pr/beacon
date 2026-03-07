import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/safety/safety_check_service.dart';

class SafetyCheckProvider extends ChangeNotifier {
  final SafetyCheckService _service = SafetyCheckService();
  StreamSubscription? _subscription;

  bool _isActive = false;
  bool _hasExpired = false;
  Duration _remaining = Duration.zero;
  String? _triggerReason;

  bool get isActive => _isActive;
  bool get hasExpired => _hasExpired;
  Duration get remaining => _remaining;
  String? get triggerReason => _triggerReason;
  SafetyCheckService get service => _service;

  SafetyCheckProvider() {
    _subscription = _service.stateStream.listen((state) {
      _isActive = state.isActive;
      _hasExpired = state.hasExpired;
      _remaining = state.remaining;
      _triggerReason = state.triggerReason;
      notifyListeners();
    });
  }

  Future<void> startCheck({required String reason, Duration? duration}) async {
    await _service.startCheck(reason: reason, duration: duration);
  }

  void confirmSafe() => _service.confirmSafe();
  void cancel() => _service.cancel();

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
