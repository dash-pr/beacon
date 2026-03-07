import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_config.dart';
import '../../models/message_model.dart';
import '../../services/mesh/ble_mesh_service.dart';
import '../../main.dart' as app;

class SafetyCheckService {
  Timer? _countdownTimer;
  Timer? _tickTimer;
  DateTime? _expiresAt;
  String? _triggerReason;
  double? _lastLat;
  double? _lastLng;
  bool _isActive = false;
  bool _hasExpired = false;

  final _stateController = StreamController<SafetyCheckState>.broadcast();
  Stream<SafetyCheckState> get stateStream => _stateController.stream;

  bool get isActive => _isActive;
  bool get hasExpired => _hasExpired;
  String? get triggerReason => _triggerReason;

  Duration get remaining {
    if (_expiresAt == null || !_isActive) return Duration.zero;
    final diff = _expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> startCheck({
    required String reason,
    Duration? duration,
  }) async {
    if (_isActive) return;

    _triggerReason = reason;
    _hasExpired = false;
    final dur = duration ?? AppConfig.safetyCheckDemoDuration;
    _expiresAt = DateTime.now().add(dur);
    _isActive = true;

    // Grab GPS once
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 5));
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
    } catch (_) {
      // Location unavailable
    }

    _countdownTimer = Timer(dur, _onTimerExpired);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _emitState();
    });
    _emitState();
  }

  void confirmSafe() {
    _countdownTimer?.cancel();
    _tickTimer?.cancel();
    _isActive = false;
    _hasExpired = false;
    _emitState();
  }

  void cancel() {
    confirmSafe();
  }

  void _onTimerExpired() {
    _tickTimer?.cancel();
    _isActive = false;
    _hasExpired = true;
    _emitState();

    // Construct and send auto-SOS
    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: app.deviceId,
      senderName: app.displayName,
      content:
          'AUTO-SOS: ${app.displayName} has not confirmed safety after ${AppConfig.safetyCheckDemoDuration.inMinutes} minutes. '
          'Last known location: ${_lastLat?.toStringAsFixed(4) ?? "unknown"}, ${_lastLng?.toStringAsFixed(4) ?? "unknown"}. '
          'Triggered by: ${_triggerReason ?? "manual"}.',
      typeIndex: MessageType.sos.index,
      priorityIndex: Priority.sos.index,
      timestamp: DateTime.now(),
      lat: _lastLat,
      lng: _lastLng,
    );

    // Save to Hive
    app.messageBox.add(message);

    // Broadcast via BLE mesh
    BleMeshService().sendMessage(message);
  }

  void _emitState() {
    _stateController.add(SafetyCheckState(
      isActive: _isActive,
      hasExpired: _hasExpired,
      remaining: remaining,
      triggerReason: _triggerReason,
    ));
  }

  void dispose() {
    _countdownTimer?.cancel();
    _tickTimer?.cancel();
    _stateController.close();
  }
}

class SafetyCheckState {
  final bool isActive;
  final bool hasExpired;
  final Duration remaining;
  final String? triggerReason;

  const SafetyCheckState({
    required this.isActive,
    required this.hasExpired,
    required this.remaining,
    this.triggerReason,
  });
}
