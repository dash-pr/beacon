import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'models/message_model.dart';

late Box<MessageModel> messageBox;
late Box settingsBox;
late String deviceId;
late String displayName;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MessageModelAdapter());

  messageBox = await Hive.openBox<MessageModel>('messages');
  settingsBox = await Hive.openBox('settings');

  deviceId = settingsBox.get('deviceId') ?? const Uuid().v4();
  displayName = settingsBox.get('displayName') ?? 'User ${deviceId.substring(0, 4)}';
  await settingsBox.put('deviceId', deviceId);
  await settingsBox.put('displayName', displayName);

  runApp(const TasukeApp());
}
