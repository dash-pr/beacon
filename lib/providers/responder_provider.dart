import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import '../main.dart' as app;

class ResponderProvider extends ChangeNotifier {
  String _activeFilter = 'all';
  final List<MessageModel> _demoMessages = [];
  bool _demoLoaded = false;

  String get activeFilter => _activeFilter;

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void _ensureDemo() {
    if (_demoLoaded) return;
    _demoLoaded = true;
    final now = DateTime.now();
    const uuid = Uuid();

    _demoMessages.addAll([
      // SOS messages with locations around Tokyo
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-tanaka',
        senderName: 'Tanaka Yuki',
        content: 'SOS — Trapped under debris after building collapse, 3rd floor Shibuya office',
        typeIndex: MessageType.sos.index,
        priorityIndex: Priority.sos.index,
        timestamp: now.subtract(const Duration(minutes: 3)),
        lat: 35.6595, lng: 139.7004,
      ),
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-sato',
        senderName: 'Sato Kenji',
        content: 'SOS — Severe injury, broken leg, cannot move. Near Shinjuku station east exit',
        typeIndex: MessageType.sos.index,
        priorityIndex: Priority.sos.index,
        timestamp: now.subtract(const Duration(minutes: 7)),
        lat: 35.6896, lng: 139.7006,
      ),
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-yamamoto',
        senderName: 'Yamamoto Hana',
        content: 'SOS — Gas leak detected in apartment building, residents evacuating',
        typeIndex: MessageType.sos.index,
        priorityIndex: Priority.sos.index,
        timestamp: now.subtract(const Duration(minutes: 12)),
        lat: 35.7090, lng: 139.7320,
      ),
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-suzuki',
        senderName: 'Suzuki Aoi',
        content: 'SOS — Elderly person having chest pains, needs immediate medical help in Ikebukuro',
        typeIndex: MessageType.sos.index,
        priorityIndex: Priority.sos.index,
        timestamp: now.subtract(const Duration(minutes: 18)),
        lat: 35.7295, lng: 139.7109,
      ),
      // Urgent messages
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-nakamura',
        senderName: 'Nakamura Ren',
        content: 'Road blocked by fallen tree near Ueno Park. Fire truck requested.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.urgent.index,
        timestamp: now.subtract(const Duration(minutes: 5)),
        lat: 35.7146, lng: 139.7732,
      ),
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-watanabe',
        senderName: 'Watanabe Mei',
        content: 'Water main burst flooding Roppongi intersection. Traffic diverted.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.urgent.index,
        timestamp: now.subtract(const Duration(minutes: 10)),
        lat: 35.6627, lng: 139.7312,
      ),
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-ito',
        senderName: 'Ito Haruto',
        content: 'Multiple aftershocks felt in Odaiba area. Building evacuation underway.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.urgent.index,
        timestamp: now.subtract(const Duration(minutes: 15)),
        lat: 35.6268, lng: 139.7768,
      ),
      // Normal messages
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-kobayashi',
        senderName: 'Kobayashi Yuto',
        content: 'Power restored in Meguro ward. All clear for residents to return.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(minutes: 20)),
        lat: 35.6339, lng: 139.7155,
      ),
      MessageModel(
        id: uuid.v4(),
        senderId: 'demo-yoshida',
        senderName: 'Yoshida Sakura',
        content: 'Shelter at Minato City Hall is at capacity. Redirecting to Azabu Community Center.',
        typeIndex: MessageType.text.index,
        priorityIndex: Priority.normal.index,
        timestamp: now.subtract(const Duration(minutes: 25)),
        lat: 35.6581, lng: 139.7514,
      ),
    ]);
  }

  List<MessageModel> get _allMessages {
    _ensureDemo();
    final hiveMessages = app.messageBox.values.toList();
    return [..._demoMessages, ...hiveMessages];
  }

  List<MessageModel> get filteredMessages {
    var messages = _allMessages;

    switch (_activeFilter) {
      case 'sos':
        messages = messages.where((m) => m.priority == Priority.sos).toList();
      case 'urgent':
        messages = messages
            .where((m) =>
                m.priority == Priority.sos || m.priority == Priority.urgent)
            .toList();
      case 'hasLocation':
        messages = messages.where((m) => m.lat != null && m.lng != null).toList();
      case 'last30':
        final cutoff = DateTime.now().subtract(const Duration(minutes: 30));
        messages = messages.where((m) => m.timestamp.isAfter(cutoff)).toList();
    }

    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  int get sosCount =>
      _allMessages.where((m) => m.priority == Priority.sos).length;

  int get urgentCount =>
      _allMessages.where((m) => m.priority == Priority.urgent).length;

  int get totalCount => _allMessages.length;

  List<MessageModel> get messagesWithLocation =>
      _allMessages.where((m) => m.lat != null && m.lng != null).toList();

  void refresh() => notifyListeners();
}
