import 'package:flutter/foundation.dart';

import '../models/message_model.dart';
import '../main.dart' as app;

class ResponderProvider extends ChangeNotifier {
  String _activeFilter = 'all';

  String get activeFilter => _activeFilter;

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  List<MessageModel> get filteredMessages {
    var messages = app.messageBox.values.toList();

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
      app.messageBox.values.where((m) => m.priority == Priority.sos).length;

  int get urgentCount =>
      app.messageBox.values.where((m) => m.priority == Priority.urgent).length;

  int get totalCount => app.messageBox.values.length;

  List<MessageModel> get messagesWithLocation =>
      app.messageBox.values.where((m) => m.lat != null && m.lng != null).toList();

  void refresh() => notifyListeners();
}
