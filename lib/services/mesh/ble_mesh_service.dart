import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart' as peripheral;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants/app_config.dart';
import '../../models/message_model.dart';
import '../../main.dart' as app;

class BleMeshService {
  static final BleMeshService _instance = BleMeshService._();
  factory BleMeshService() => _instance;
  BleMeshService._();

  final Set<String> _seenMessageIds = {};
  final _messageController = StreamController<MessageModel>.broadcast();
  final Map<String, BluetoothCharacteristic> _centralCharacteristics = {};
  final Set<String> _connectingDevices = {};
  bool _isRunning = false;

  Stream<MessageModel> get onMessageReceived => _messageController.stream;
  int get connectedDeviceCount => _centralCharacteristics.length;
  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    await _startPeripheral();
    await _startCentral();
  }

  Future<void> stop() async {
    _isRunning = false;
    try {
      await peripheral.BlePeripheral.stopAdvertising();
    } catch (_) {}
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    for (final device in _centralCharacteristics.keys.toList()) {
      try {
        final fbpDevice = BluetoothDevice.fromId(device);
        await fbpDevice.disconnect();
      } catch (_) {}
    }
    _centralCharacteristics.clear();
    _connectingDevices.clear();
  }

  // === PERIPHERAL ROLE (ble_peripheral) ===
  Future<void> _startPeripheral() async {
    try {
      await peripheral.BlePeripheral.initialize();

      peripheral.BlePeripheral.setWriteRequestCallback(
        (String deviceId, String characteristicId, int offset, Uint8List? value) {
          if (value != null) {
            _handleIncomingData(value);
          }
          return peripheral.WriteRequestResult(
            status: 0,
          );
        },
      );

      await peripheral.BlePeripheral.addService(
        peripheral.BleService(
          uuid: AppConfig.serviceUuid,
          primary: true,
          characteristics: [
            peripheral.BleCharacteristic(
              uuid: AppConfig.characteristicUuid,
              properties: [
                peripheral.CharacteristicProperties.write.index,
                peripheral.CharacteristicProperties.writeWithoutResponse.index,
                peripheral.CharacteristicProperties.notify.index,
                peripheral.CharacteristicProperties.read.index,
              ],
              permissions: [
                peripheral.AttributePermissions.readable.index,
                peripheral.AttributePermissions.writeable.index,
              ],
            ),
          ],
        ),
      );

      await peripheral.BlePeripheral.startAdvertising(
        services: [AppConfig.serviceUuid],
        localName: 'Tasuke',
      );
    } catch (e) {
      // Peripheral may not be supported on all devices
    }
  }

  // === CENTRAL ROLE (flutter_blue_plus) ===
  Future<void> _startCentral() async {
    try {
      FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          final serviceUuids = result.advertisementData.serviceUuids;
          if (serviceUuids.any((uuid) => uuid.str == AppConfig.serviceUuid)) {
            _connectToPeripheral(result.device);
          }
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [Guid(AppConfig.serviceUuid)],
        androidUsesFineLocation: false,
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 15),
      );
    } catch (e) {
      // Scan may fail if BLE is off
    }
  }

  Future<void> _connectToPeripheral(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    if (_centralCharacteristics.containsKey(deviceId)) return;
    if (_connectingDevices.contains(deviceId)) return;
    _connectingDevices.add(deviceId);

    try {
      await device.connect(
        autoConnect: true,
        timeout: const Duration(seconds: 10),
      );

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _centralCharacteristics.remove(deviceId);
          _connectingDevices.remove(deviceId);
        }
      });

      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid == Guid(AppConfig.serviceUuid)) {
          for (final char in service.characteristics) {
            if (char.uuid == Guid(AppConfig.characteristicUuid)) {
              _centralCharacteristics[deviceId] = char;

              try {
                await char.setNotifyValue(true);
                char.onValueReceived.listen((value) {
                  _handleIncomingData(Uint8List.fromList(value));
                });
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      _connectingDevices.remove(deviceId);
    }
  }

  // === SEND MESSAGE ===
  Future<void> sendMessage(MessageModel message) async {
    _seenMessageIds.add(message.id);
    final jsonBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(message.toJson())),
    );

    // Save to Hive
    await app.messageBox.add(message);

    // Write to all connected peripherals via Central role
    final failedDevices = <String>[];
    for (final entry in _centralCharacteristics.entries) {
      try {
        await entry.value.write(jsonBytes, withoutResponse: true);
      } catch (_) {
        failedDevices.add(entry.key);
      }
    }
    for (final id in failedDevices) {
      _centralCharacteristics.remove(id);
    }

    // Notify via Peripheral role
    try {
      await peripheral.BlePeripheral.updateCharacteristic(
        characteristicId: AppConfig.characteristicUuid,
        value: jsonBytes,
      );
    } catch (_) {}
  }

  // === HANDLE INCOMING DATA ===
  void _handleIncomingData(Uint8List data) {
    try {
      final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      final message = MessageModel.fromJson(json);

      if (_seenMessageIds.contains(message.id)) return;
      _seenMessageIds.add(message.id);

      app.messageBox.add(message);
      _messageController.add(message);

      // 1-hop rebroadcast
      if (message.hopCount < AppConfig.maxHopCount) {
        final rebroadcast = message.copyWith(hopCount: message.hopCount + 1);
        final jsonBytes = Uint8List.fromList(
          utf8.encode(jsonEncode(rebroadcast.toJson())),
        );

        for (final char in _centralCharacteristics.values) {
          try {
            char.write(jsonBytes, withoutResponse: true);
          } catch (_) {}
        }

        try {
          peripheral.BlePeripheral.updateCharacteristic(
            characteristicId: AppConfig.characteristicUuid,
            value: jsonBytes,
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  void dispose() {
    _messageController.close();
  }
}
