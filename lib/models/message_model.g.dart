// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 0;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      senderId: fields[1] as String,
      senderName: fields[2] as String,
      content: fields[3] as String,
      typeIndex: fields[4] as int,
      priorityIndex: fields[5] as int,
      timestamp: fields[6] as DateTime,
      isSynced: fields[7] as bool,
      hopCount: fields[8] as int,
      lat: fields[9] as double?,
      lng: fields[10] as double?,
      imageBase64: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.senderName)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.typeIndex)
      ..writeByte(5)
      ..write(obj.priorityIndex)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.hopCount)
      ..writeByte(9)
      ..write(obj.lat)
      ..writeByte(10)
      ..write(obj.lng)
      ..writeByte(11)
      ..write(obj.imageBase64);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
