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

  void init(BleMeshService meshService) {
    loadFromHive();
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
    final allMessages = app.messageBox.values.toList();
    for (final m in allMessages) {
      _trackUser(m);
      if (m.recipientId == null || m.recipientId == app.deviceId || m.senderId == app.deviceId) {
        _messages.add(m);
      }
    }
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
