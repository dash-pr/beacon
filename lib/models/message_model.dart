import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String senderName;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final int typeIndex;

  @HiveField(5)
  final int priorityIndex;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  final int hopCount;

  @HiveField(9)
  final double? lat;

  @HiveField(10)
  final double? lng;

  @HiveField(11)
  final String? imageBase64;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.typeIndex,
    required this.priorityIndex,
    required this.timestamp,
    this.isSynced = false,
    this.hopCount = 0,
    this.lat,
    this.lng,
    this.imageBase64,
  });

  MessageType get type => MessageType.values[typeIndex];
  Priority get priority => Priority.values[priorityIndex];

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    int? typeIndex,
    int? priorityIndex,
    DateTime? timestamp,
    bool? isSynced,
    int? hopCount,
    double? lat,
    double? lng,
    String? imageBase64,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      typeIndex: typeIndex ?? this.typeIndex,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      hopCount: hopCount ?? this.hopCount,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sid': senderId,
      'sn': senderName,
      'c': content,
      't': typeIndex,
      'p': priorityIndex,
      'ts': timestamp.millisecondsSinceEpoch,
      'h': hopCount,
      if (lat != null) 'la': lat,
      if (lng != null) 'lo': lng,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['sid'] as String,
      senderName: json['sn'] as String,
      content: json['c'] as String,
      typeIndex: json['t'] as int,
      priorityIndex: json['p'] as int,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      hopCount: json['h'] as int? ?? 0,
      lat: (json['la'] as num?)?.toDouble(),
      lng: (json['lo'] as num?)?.toDouble(),
    );
  }
}

enum MessageType { text, voice, image, sos, system }

enum Priority { normal, urgent, sos }
