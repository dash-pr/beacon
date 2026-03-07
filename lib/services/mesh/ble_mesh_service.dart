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

    // Periodic rescan — Android throttles BLE scans after ~30s
    _rescanTimer = Timer.periodic(const Duration(seconds: 25), (_) {
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
  }

  // === PERIPHERAL ROLE (ble_peripheral) ===
  Future<void> _startPeripheral() async {
    try {
      // Set ALL callbacks BEFORE initialize (per ble_peripheral docs)
      peripheral.BlePeripheral.setWriteRequestCallback(
        (String deviceId, String characteristicId, int offset, Uint8List? value) {
          _log('Write from $deviceId, ${value?.length ?? 0} bytes');
          if (value != null) {
            _handleIncomingData(value);
          }
          return null; // Return null for success (per example)
        },
      );

      peripheral.BlePeripheral.setReadRequestCallback(
        (String deviceId, String characteristicId, int offset, Uint8List? value) {
          _log('Read request from $deviceId');
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

      // Android only — track peripheral-side connections
      peripheral.BlePeripheral.setConnectionStateChangeCallback(
        (String deviceId, bool connected) {
          _log('Peripheral connection: $deviceId connected=$connected');
        },
      );

      peripheral.BlePeripheral.setMtuChangeCallback(
        (String deviceId, int mtu) {
          _log('MTU changed: $deviceId -> $mtu');
        },
      );

      await peripheral.BlePeripheral.initialize();
      _log('Peripheral initialized');

      // Use a completer to wait for service registration
      final serviceCompleter = Completer<void>();
      peripheral.BlePeripheral.setServiceAddedCallback(
        (String serviceId, String? error) {
          if (error != null) {
            _log('Service add failed: $error');
            if (!serviceCompleter.isCompleted) serviceCompleter.completeError(error);
          } else {
            _log('Service added: $serviceId');
            if (!serviceCompleter.isCompleted) serviceCompleter.complete();
          }
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
                peripheral.CharacteristicProperties.read.index,
                peripheral.CharacteristicProperties.write.index,
                peripheral.CharacteristicProperties.writeWithoutResponse.index,
                peripheral.CharacteristicProperties.notify.index,
              ],
              permissions: [
                peripheral.AttributePermissions.readable.index,
                peripheral.AttributePermissions.writeable.index,
              ],
            ),
          ],
        ),
      );

      // Wait for service to actually be registered (with timeout)
      try {
        await serviceCompleter.future.timeout(const Duration(seconds: 5));
      } catch (e) {
        _log('Service registration timeout/error: $e');
      }

      // Now start advertising (after service is registered)
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
      FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          final serviceUuids = result.advertisementData.serviceUuids;
          final name = result.advertisementData.advName;
          final matchesService = serviceUuids.any(
            (uuid) => uuid.str.toLowerCase() == AppConfig.serviceUuid.toLowerCase(),
          );
          final matchesName = name == 'Beacon';

          if (matchesService || matchesName) {
            _log('Found peer: ${result.device.remoteId} name=$name rssi=${result.rssi}');
            _connectToPeripheral(result.device);
          }
        }
      });

      // Scan with fine location enabled (we have the permission)
      await FlutterBluePlus.startScan(
        androidUsesFineLocation: true,
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 15),
      );
      _isScanning = true;
      _log('Central scan started');
    } catch (e) {
      _log('Central scan error: $e');
    }
  }

  Future<void> _restartScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 500));
      await FlutterBluePlus.startScan(
        androidUsesFineLocation: true,
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 15),
      );
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
      _log('Connecting to $deviceId...');
      await device.connect(
        autoConnect: false, // false = connect immediately, faster
        timeout: const Duration(seconds: 15),
      );
      _log('Connected to $deviceId');

      // Negotiate larger MTU — default 20 bytes is too small for JSON messages
      try {
        final mtu = await device.requestMtu(512);
        _log('MTU negotiated: $mtu for $deviceId');
      } catch (e) {
        _log('MTU negotiation failed: $e');
      }

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _log('Disconnected from $deviceId');
          _centralCharacteristics.remove(deviceId);
          _connectingDevices.remove(deviceId);
        }
      });

      final services = await device.discoverServices();
      _log('Discovered ${services.length} services on $deviceId');

      bool foundChar = false;
      for (final service in services) {
        if (service.uuid.str.toLowerCase() == AppConfig.serviceUuid.toLowerCase()) {
          _log('Found Beacon service on $deviceId');
          for (final char in service.characteristics) {
            if (char.uuid.str.toLowerCase() == AppConfig.characteristicUuid.toLowerCase()) {
              _centralCharacteristics[deviceId] = char;
              foundChar = true;
              _log('Found Beacon characteristic on $deviceId — PEER READY');

              try {
                await char.setNotifyValue(true);
                char.onValueReceived.listen((value) {
                  _log('Notification from $deviceId: ${value.length} bytes');
                  _handleIncomingData(Uint8List.fromList(value));
                });
                _log('Subscribed to notifications on $deviceId');
              } catch (e) {
                _log('Notification subscribe error: $e');
              }
            }
          }
        }
      }
      if (!foundChar) {
        _log('WARNING: Beacon service/characteristic NOT found on $deviceId');
        // List what we did find for debugging
        for (final s in services) {
          _log('  Service: ${s.uuid}');
        }
      }
    } catch (e) {
      _log('Connection error for $deviceId: $e');
      _connectingDevices.remove(deviceId);
    }
  }

  // === SEND MESSAGE ===
  Future<void> sendMessage(MessageModel message) async {
    _seenMessageIds.add(message.id);
    final jsonStr = jsonEncode(message.toJson());
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonStr));
    _log('Sending message: ${jsonBytes.length} bytes to ${_centralCharacteristics.length} peers');

    // Save to Hive
    await app.messageBox.add(message);

    // Write to all connected peripherals via Central role
    final failedDevices = <String>[];
    for (final entry in _centralCharacteristics.entries) {
      try {
        await entry.value.write(jsonBytes, withoutResponse: false);
        _log('Wrote to ${entry.key} (with response)');
      } catch (e) {
        _log('Write-with-response failed for ${entry.key}: $e');
        try {
          await entry.value.write(jsonBytes, withoutResponse: true);
          _log('Wrote to ${entry.key} (without response, fallback)');
        } catch (e2) {
          _log('Write failed completely for ${entry.key}: $e2');
          failedDevices.add(entry.key);
        }
      }
    }
    for (final id in failedDevices) {
      _centralCharacteristics.remove(id);
    }

    // Notify via Peripheral role (for any centrals connected to us)
    try {
      await peripheral.BlePeripheral.updateCharacteristic(
        characteristicId: AppConfig.characteristicUuid,
        value: jsonBytes,
      );
      _log('Peripheral notification sent');
    } catch (e) {
      _log('Peripheral notification error: $e');
    }
  }

  // === HANDLE INCOMING DATA ===
  void _handleIncomingData(Uint8List data) {
    try {
      final jsonStr = utf8.decode(data);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final message = MessageModel.fromJson(json);

      if (_seenMessageIds.contains(message.id)) {
        _log('Duplicate message ${message.id.substring(0, 8)}, skipping');
        return;
      }
      _seenMessageIds.add(message.id);
      _log('Received message from ${message.senderName}: "${message.content.substring(0, message.content.length.clamp(0, 30))}..."');

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
    } catch (e) {
      _log('Parse error: $e, data length: ${data.length}');
    }
  }

  void dispose() {
    _rescanTimer?.cancel();
    _messageController.close();
  }
}
