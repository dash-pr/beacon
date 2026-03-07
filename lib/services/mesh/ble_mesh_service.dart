import 'dart:async';
import 'dart:convert';

import 'package:ble_peripheral/ble_peripheral.dart' as peripheral;
import 'package:flutter/foundation.dart';
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
  bool _isAdvertising = false;
  bool _isScanning = false;
  bool _peripheralReady = false;
  Timer? _rescanTimer;

  // Debug log for UI visibility
  final List<String> _debugLog = [];
  List<String> get debugLog => List.unmodifiable(_debugLog);

  Stream<MessageModel> get onMessageReceived => _messageController.stream;
  int get connectedDeviceCount => _centralCharacteristics.length;
  bool get isRunning => _isRunning;
  bool get isAdvertising => _isAdvertising;
  bool get isScanning => _isScanning;

  void _log(String msg) {
    debugPrint('[BleMesh] $msg');
    _debugLog.add('${DateTime.now().toString().substring(11, 19)} $msg');
    if (_debugLog.length > 50) _debugLog.removeAt(0);
  }

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    await _startPeripheral();
    await _startCentral();

    // Periodic rescan — Android throttles BLE scans
    _rescanTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isRunning) _restartScan();
    });
  }

  Future<void> stop() async {
    _isRunning = false;
    _rescanTimer?.cancel();
    try {
      await peripheral.BlePeripheral.stopAdvertising();
    } catch (_) {}
    _isAdvertising = false;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _isScanning = false;
    for (final device in _centralCharacteristics.keys.toList()) {
      try {
        final fbpDevice = BluetoothDevice.fromId(device);
        await fbpDevice.disconnect();
      } catch (_) {}
    }
    _centralCharacteristics.clear();
    _connectingDevices.clear();
    _peripheralReady = false;
  }

  // === PERIPHERAL ROLE (ble_peripheral) ===
  Future<void> _startPeripheral() async {
    try {
      // Set ALL callbacks BEFORE initialize (per ble_peripheral docs)
      peripheral.BlePeripheral.setWriteRequestCallback(
        (String deviceId, String characteristicId, int offset, Uint8List? value) {
          _log('Write from ${deviceId.substring(0, 8)}..., ${value?.length ?? 0}B');
          if (value != null) {
            _handleIncomingData(value);
          }
          return null;
        },
      );

      peripheral.BlePeripheral.setReadRequestCallback(
        (String deviceId, String characteristicId, int offset, Uint8List? value) {
          _log('Read req from ${deviceId.substring(0, 8)}...');
          return peripheral.ReadRequestResult(
            value: Uint8List.fromList(utf8.encode(app.deviceId)),
          );
        },
      );

      peripheral.BlePeripheral.setAdvertisingStatusUpdateCallback(
        (bool advertising, String? error) {
          _isAdvertising = advertising;
          if (error != null) {
            _log('Advertising error: $error');
          } else {
            _log('Advertising: $advertising');
          }
        },
      );

      peripheral.BlePeripheral.setConnectionStateChangeCallback(
        (String deviceId, bool connected) {
          _log('Periph conn: ${deviceId.substring(0, 8)}... connected=$connected');
        },
      );

      peripheral.BlePeripheral.setMtuChangeCallback(
        (String deviceId, int mtu) {
          _log('MTU: ${deviceId.substring(0, 8)}... -> $mtu');
        },
      );

      await peripheral.BlePeripheral.initialize();
      _log('Peripheral initialized');

      // Add service and wait for registration
      await peripheral.BlePeripheral.addService(
        peripheral.BleService(
          uuid: AppConfig.serviceUuid,
          primary: true,
          characteristics: [
            peripheral.BleCharacteristic(
              uuid: AppConfig.characteristicUuid,
              properties: [
                peripheral.CharacteristicProperties.read.index,
                peripheral.CharacteristicProperties.write.index,
                peripheral.CharacteristicProperties.writeWithoutResponse.index,
                peripheral.CharacteristicProperties.notify.index,
              ],
              permissions: [
                peripheral.AttributePermissions.readable.index,
                peripheral.AttributePermissions.writeable.index,
              ],
              value: null,
            ),
          ],
        ),
      );
      _log('Service registered');

      // Verify service was actually added
      try {
        final services = await peripheral.BlePeripheral.getServices();
        _log('Registered services: $services');
        if (services.any((s) => s.toLowerCase() == AppConfig.serviceUuid.toLowerCase())) {
          _peripheralReady = true;
          _log('Service verified OK');
        } else {
          _log('WARNING: Service not in getServices() list!');
        }
      } catch (e) {
        _log('getServices check failed: $e');
        // Assume it worked if addService didn't throw
        _peripheralReady = true;
      }

      // Start advertising after service is registered
      await peripheral.BlePeripheral.startAdvertising(
        services: [AppConfig.serviceUuid],
        localName: 'Beacon',
      );
      _log('Advertising started');
    } catch (e) {
      _log('Peripheral setup error: $e');
    }
  }

  // === CENTRAL ROLE (flutter_blue_plus) ===
  Future<void> _startCentral() async {
    try {
      int _scanResultCount = 0;
      FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          final serviceUuids = result.advertisementData.serviceUuids;
          final name = result.advertisementData.advName;
          final matchesService = serviceUuids.any(
            (uuid) => uuid.str.toLowerCase() == AppConfig.serviceUuid.toLowerCase(),
          );
          final matchesName = name.contains('Beacon');

          // Log every 10th non-matching device for debug visibility
          _scanResultCount++;
          if (_scanResultCount <= 5 || _scanResultCount % 20 == 0) {
            final svcStrs = serviceUuids.map((u) => u.str).join(',');
            _log('Scan#$_scanResultCount: name="$name" svc=[$svcStrs] rssi=${result.rssi}');
          }

          if (matchesService || matchesName) {
            _log('MATCH: ${result.device.remoteId.str.substring(0, 8)}... name=$name rssi=${result.rssi} svc=$matchesService');
            _connectToPeripheral(result.device);
          }
        }
      });

      // Broad scan — no UUID filter because Android 31-byte advertisement
      // packets may drop the 128-bit service UUID when localName is included.
      // We filter by name "Beacon" in the callback above.
      await FlutterBluePlus.startScan(
        androidUsesFineLocation: true,
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 30),
      );
      _isScanning = true;
      _log('Scan started (broad, continuous)');
    } catch (e) {
      _log('Central scan error: $e');
    }
  }

  Future<void> _restartScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      await Future.delayed(const Duration(seconds: 1));

      await FlutterBluePlus.startScan(
        androidUsesFineLocation: true,
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 30),
      );
      _isScanning = true;
      _log('Scan restarted');
    } catch (e) {
      _log('Rescan error: $e');
    }
  }

  Future<void> _connectToPeripheral(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    if (_centralCharacteristics.containsKey(deviceId)) return;
    if (_connectingDevices.contains(deviceId)) return;
    _connectingDevices.add(deviceId);

    try {
      _log('Connecting ${deviceId.substring(0, 8)}...');
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );
      _log('Connected ${deviceId.substring(0, 8)}...');

      // Negotiate larger MTU
      try {
        final mtu = await device.requestMtu(512);
        _log('MTU=$mtu for ${deviceId.substring(0, 8)}...');
      } catch (e) {
        _log('MTU fail: $e');
      }

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _log('Disconnected ${deviceId.substring(0, 8)}...');
          _centralCharacteristics.remove(deviceId);
          _connectingDevices.remove(deviceId);
        }
      });

      final services = await device.discoverServices();
      _log('Discovered ${services.length} services on ${deviceId.substring(0, 8)}...');

      bool foundChar = false;
      for (final service in services) {
        if (service.uuid.str.toLowerCase() == AppConfig.serviceUuid.toLowerCase()) {
          _log('Found Beacon service');
          for (final char in service.characteristics) {
            if (char.uuid.str.toLowerCase() == AppConfig.characteristicUuid.toLowerCase()) {
              _centralCharacteristics[deviceId] = char;
              foundChar = true;
              _log('PEER READY: ${deviceId.substring(0, 8)}...');

              try {
                await char.setNotifyValue(true);
                char.onValueReceived.listen((value) {
                  _log('Notif from ${deviceId.substring(0, 8)}...: ${value.length}B');
                  _handleIncomingData(Uint8List.fromList(value));
                });
                _log('Subscribed to notifications');
              } catch (e) {
                _log('Notify subscribe error: $e');
              }
            }
          }
        }
      }
      if (!foundChar) {
        _log('WARNING: Beacon char NOT found on ${deviceId.substring(0, 8)}...');
        for (final s in services) {
          _log('  svc: ${s.uuid}');
        }
        // Disconnect — this device doesn't have our service
        try {
          await device.disconnect();
        } catch (_) {}
        _connectingDevices.remove(deviceId);
      }
    } catch (e) {
      _log('Connect error ${deviceId.substring(0, 8)}...: $e');
      _connectingDevices.remove(deviceId);
    }
  }

  // === SEND MESSAGE ===
  Future<void> sendMessage(MessageModel message) async {
    _seenMessageIds.add(message.id);
    final jsonStr = jsonEncode(message.toJson());
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonStr));
    _log('Sending ${jsonBytes.length}B to ${_centralCharacteristics.length} peers');

    // Save to Hive
    await app.messageBox.add(message);

    // Write to all connected peripherals via Central role
    final failedDevices = <String>[];
    for (final entry in _centralCharacteristics.entries) {
      try {
        await entry.value.write(jsonBytes, withoutResponse: false);
        _log('Wrote to ${entry.key.substring(0, 8)}...');
      } catch (e) {
        try {
          await entry.value.write(jsonBytes, withoutResponse: true);
          _log('Wrote (noResp) to ${entry.key.substring(0, 8)}...');
        } catch (e2) {
          _log('Write failed ${entry.key.substring(0, 8)}...: $e2');
          failedDevices.add(entry.key);
        }
      }
    }
    for (final id in failedDevices) {
      _centralCharacteristics.remove(id);
    }

    // Notify via Peripheral role (for any centrals connected to us)
    if (_peripheralReady) {
      try {
        await peripheral.BlePeripheral.updateCharacteristic(
          characteristicId: AppConfig.characteristicUuid,
          value: jsonBytes,
        );
        _log('Peripheral notify sent');
      } catch (e) {
        _log('Peripheral notify error: $e');
        // Try to re-register the service if characteristic not found
        if (e.toString().contains('Characteristic not found')) {
          _log('Attempting service re-registration...');
          _peripheralReady = false;
          _reRegisterService();
        }
      }
    }
  }

  /// Re-register the GATT service if the native side lost it
  Future<void> _reRegisterService() async {
    try {
      // Clear and re-add
      try {
        await peripheral.BlePeripheral.clearServices();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));

      await peripheral.BlePeripheral.addService(
        peripheral.BleService(
          uuid: AppConfig.serviceUuid,
          primary: true,
          characteristics: [
            peripheral.BleCharacteristic(
              uuid: AppConfig.characteristicUuid,
              properties: [
                peripheral.CharacteristicProperties.read.index,
                peripheral.CharacteristicProperties.write.index,
                peripheral.CharacteristicProperties.writeWithoutResponse.index,
                peripheral.CharacteristicProperties.notify.index,
              ],
              permissions: [
                peripheral.AttributePermissions.readable.index,
                peripheral.AttributePermissions.writeable.index,
              ],
              value: null,
            ),
          ],
        ),
      );
      _peripheralReady = true;
      _log('Service re-registered OK');

      // Restart advertising
      try {
        await peripheral.BlePeripheral.stopAdvertising();
      } catch (_) {}
      await peripheral.BlePeripheral.startAdvertising(
        services: [AppConfig.serviceUuid],
        localName: 'Beacon',
      );
      _log('Re-advertising started');
    } catch (e) {
      _log('Service re-registration failed: $e');
    }
  }

  // === HANDLE INCOMING DATA ===
  void _handleIncomingData(Uint8List data) {
    try {
      final jsonStr = utf8.decode(data);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final message = MessageModel.fromJson(json);

      if (_seenMessageIds.contains(message.id)) return;
      _seenMessageIds.add(message.id);
      _log('Recv from ${message.senderName}: "${message.content.substring(0, message.content.length.clamp(0, 30))}"');

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

        if (_peripheralReady) {
          try {
            peripheral.BlePeripheral.updateCharacteristic(
              characteristicId: AppConfig.characteristicUuid,
              value: jsonBytes,
            );
          } catch (_) {}
        }
      }
    } catch (e) {
      _log('Parse error: $e (${data.length}B)');
    }
  }

  void dispose() {
    _rescanTimer?.cancel();
    _messageController.close();
  }
}
