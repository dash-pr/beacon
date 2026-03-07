import '../../models/message_model.dart';
import '../../main.dart' as app;

class MessageQueueService {
  List<MessageModel> getMessages() {
    final messages = app.messageBox.values.toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  List<MessageModel> getUnsyncedMessages() {
    return app.messageBox.values.where((m) => !m.isSynced).toList();
  }

  Future<void> markSynced(String messageId) async {
    final messages = app.messageBox.values.toList();
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].id == messageId) {
        messages[i].isSynced = true;
        await messages[i].save();
        break;
      }
    }
  }
}
