import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/sos_detector.dart';
import '../models/message_model.dart';
import '../services/mesh/ble_mesh_service.dart';
import '../main.dart' as app;

class MessageProvider extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  StreamSubscription? _meshSubscription;

  List<MessageModel> get messages => List.unmodifiable(_messages);

  void init(BleMeshService meshService) {
    loadFromHive();
    _meshSubscription = meshService.onMessageReceived.listen((message) {
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    });
  }

  void loadFromHive() {
    _messages.clear();
    _messages.addAll(app.messageBox.values.toList());
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
  }

  Future<void> sendTextMessage(String content, BleMeshService meshService) async {
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
    );

    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();

    await meshService.sendMessage(message);
  }

  void addMessage(MessageModel message) {
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
