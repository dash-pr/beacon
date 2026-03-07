import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestBlePermissions() async {
    if (kIsWeb) return false;
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      return statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestCameraPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted || status.isLimited;
  }
}
