import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  final int id;
  final String title;
  final String message;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_read')
  bool isRead;
  final String type;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}

class NotificationTypeAdapter implements TypeAdapter<Notification> {
  @override
  read(BinaryReader reader) {
    final json = reader.read();
    return Notification.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  int get typeId => 101;

  @override
  void write(BinaryWriter writer, Notification obj) {
    writer.write(obj.toJson());
  }
}
