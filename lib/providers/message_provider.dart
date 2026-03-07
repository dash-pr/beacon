import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/sos_detector.dart';
import '../models/message_model.dart';
import '../services/mesh/ble_mesh_service.dart';
import '../main.dart' as app;

class MessageProvider extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  final Map<String, String> _knownUsers = {}; // deviceId -> displayName
  StreamSubscription? _meshSubscription;
  bool _demoSeeded = false;

  static const _demoUsers = {
    'demo-tanaka': 'Tanaka Yuki',
    'demo-sato': 'Sato Kenji',
    'demo-suzuki': 'Suzuki Aoi',
    'demo-yamamoto': 'Yamamoto Hana',
    'demo-nakamura': 'Nakamura Ren',
  };

  MessageProvider() {
    // Seed demo data immediately so it's available on first build
    _seedDemo();
  }

  List<MessageModel> get messages => List.unmodifiable(_messages);
  Map<String, String> get knownUsers => Map.unmodifiable(_knownUsers);

  /// Community (broadcast) messages only
  List<MessageModel> get communityMessages =>
      _messages.where((m) => m.isBroadcast).toList();

  /// DMs for a specific user (messages between us and them)
  List<MessageModel> dmsWith(String userId) => _messages
      .where((m) =>
          (m.senderId == userId && m.recipientId == app.deviceId) ||
          (m.senderId == app.deviceId && m.recipientId == userId))
      .toList();

  /// Unique users we've had DM conversations with
  List<String> get dmUserIds {
    final ids = <String>{};
    for (final m in _messages) {
      if (m.isDm) {
        if (m.senderId == app.deviceId) {
          ids.add(m.recipientId!);
        } else if (m.recipientId == app.deviceId) {
          ids.add(m.senderId);
        }
      }
    }
    return ids.toList();
  }

  /// Unread DM count for a user
  int unreadDmCount(String userId) {
    return _messages
        .where((m) =>
            m.senderId == userId &&
            m.recipientId == app.deviceId &&
            !m.isSynced)
        .length;
  }

  void _seedDemo() {
    if (_demoSeeded) return;
    _demoSeeded = true;

    // Add demo users to known users
    _knownUsers.addAll(_demoUsers);

    // Use stable IDs so re-seeding doesn't duplicate
    final existing = _messages.map((m) => m.id).toSet();

    final now = DateTime.now();

    final demoMessages = <MessageModel>[
      // === DM conversations ===
      // Tanaka — backcountry buddy
      MessageModel(
        id: 'demo-msg-01',
        senderId: 'demo-tanaka',
        senderName: 'Tanaka Yuki',
        content: 'Hey, are you heading to the Niseko backcountry tomorrow?',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
        recipientId: app.deviceId,
      ),
      MessageModel(
        id: 'demo-msg-02',
        senderId: app.deviceId,
        senderName: app.displayName,
        content: 'Yes! Planning to hit the east face. Avalanche report looks clear.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
        recipientId: 'demo-tanaka',
      ),
      MessageModel(
        id: 'demo-msg-03',
        senderId: 'demo-tanaka',
        senderName: 'Tanaka Yuki',
        content: 'Great, I\'ll bring the beacon and probe. Meet at the trailhead at 7am?',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 5)),
        recipientId: app.deviceId,
      ),
      // Sato — emergency coordination
      MessageModel(
        id: 'demo-msg-04',
        senderId: 'demo-sato',
        senderName: 'Sato Kenji',
        content: 'The shelter at Minato City Hall is almost full. Can you check the one in Azabu?',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.urgent.index,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        recipientId: app.deviceId,
      ),
      MessageModel(
        id: 'demo-msg-05',
        senderId: app.deviceId,
        senderName: app.displayName,
        content: 'On my way there now. Will report back.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 25)),
        recipientId: 'demo-sato',
      ),
      MessageModel(
        id: 'demo-msg-06',
        senderId: 'demo-sato',
        senderName: 'Sato Kenji',
        content: 'Thanks. Water supply truck arriving at your location in 20 min.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        recipientId: app.deviceId,
      ),
      // Suzuki — medical
      MessageModel(
        id: 'demo-msg-07',
        senderId: 'demo-suzuki',
        senderName: 'Suzuki Aoi',
        content: 'Do you have any first aid supplies? There\'s an injured person near the station.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.urgent.index,
        timestamp: now.subtract(const Duration(minutes: 45)),
        recipientId: app.deviceId,
      ),
      // Yamamoto — community update
      MessageModel(
        id: 'demo-msg-08',
        senderId: 'demo-yamamoto',
        senderName: 'Yamamoto Hana',
        content: 'The gas leak in building 4 has been sealed. All clear to return.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(minutes: 30)),
        recipientId: app.deviceId,
      ),
      // Nakamura — gear check
      MessageModel(
        id: 'demo-msg-09',
        senderId: 'demo-nakamura',
        senderName: 'Nakamura Ren',
        content: 'Do you still have that extra radio? Could use one for the rescue team.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(minutes: 15)),
        recipientId: app.deviceId,
      ),
      // === Community broadcast messages ===
      MessageModel(
        id: 'demo-msg-c1',
        senderId: 'demo-sato',
        senderName: 'Sato Kenji',
        content: 'Earthquake magnitude 6.2 reported. Everyone please check in.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.urgent.index,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      MessageModel(
        id: 'demo-msg-c2',
        senderId: 'demo-yamamoto',
        senderName: 'Yamamoto Hana',
        content: 'I\'m safe. Gas smell in our building though — evacuating now.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 50)),
      ),
      MessageModel(
        id: 'demo-msg-c3',
        senderId: 'demo-tanaka',
        senderName: 'Tanaka Yuki',
        content: 'All okay in Shibuya area. Some broken glass but no injuries nearby.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
      ),
      MessageModel(
        id: 'demo-msg-c4',
        senderId: 'demo-suzuki',
        senderName: 'Suzuki Aoi',
        content: 'Water distribution point set up at Shinjuku Central Park. Bring containers.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      MessageModel(
        id: 'demo-msg-c5',
        senderId: 'demo-nakamura',
        senderName: 'Nakamura Ren',
        content: 'Road to Ueno is blocked. Use alternate route via Akihabara.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.urgent.index,
        timestamp: now.subtract(const Duration(minutes: 40)),
      ),
    ];

    // Only add messages that aren't already present
    for (final m in demoMessages) {
      if (!existing.contains(m.id)) {
        _messages.add(m);
      }
    }

    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void init(BleMeshService meshService) {
    loadFromHive();
    _seedDemo();
    _meshSubscription = meshService.onMessageReceived.listen((message) {
      _trackUser(message);
      // Only show messages addressed to us or broadcast
      if (message.recipientId == null || message.recipientId == app.deviceId) {
        _messages.add(message);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      notifyListeners();
    });
  }

  void loadFromHive() {
    _messages.clear();
    _demoSeeded = false;
    final allMessages = app.messageBox.values.toList();
    for (final m in allMessages) {
      _trackUser(m);
      if (m.recipientId == null || m.recipientId == app.deviceId || m.senderId == app.deviceId) {
        _messages.add(m);
      }
    }
    _seedDemo();
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
  }

  void _trackUser(MessageModel m) {
    if (m.senderId != app.deviceId) {
      _knownUsers[m.senderId] = m.senderName;
    }
  }

  Future<void> sendTextMessage(
    String content,
    BleMeshService meshService, {
    String? recipientId,
    double? lat,
    double? lng,
  }) async {
    final priority = SosDetector.detectPriority(content);
    final message = MessageModel(
      id: const Uuid().v4(),
      senderId: app.deviceId,
      senderName: app.displayName,
      content: content,
      typeIndex: priority == Priority.sos
          ? MessageType.sos.index
          : MessageType.text.index,
      priorityIndex: priority.index,
      timestamp: DateTime.now(),
      recipientId: recipientId,
      lat: lat,
      lng: lng,
    );

    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();

    await meshService.sendMessage(message);
  }

  void addMessage(MessageModel message) {
    _trackUser(message);
    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
  }

  List<MessageModel> get sosMessages =>
      _messages.where((m) => m.priority == Priority.sos).toList();

  List<MessageModel> get urgentMessages =>
      _messages.where((m) => m.priority == Priority.urgent).toList();

  MessageModel? get latestSos {
    final sos = sosMessages;
    if (sos.isEmpty) return null;
    final recent = sos.where(
      (m) => m.timestamp.isAfter(
        DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    );
    return recent.isEmpty ? null : recent.last;
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    super.dispose();
  }
}
