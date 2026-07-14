import 'package:vector_academy/models/user.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'session.g.dart';

@JsonSerializable()
class Session {
  final String jwt;
  final User user;

  Session({required this.jwt, required this.user});

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

class SessionTypeAdapter implements TypeAdapter<Session> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;

    return Session(jwt: json['jwt'], user: json['user']);
  }

  @override
  int get typeId => 12;

  @override
  void write(BinaryWriter writer, Session obj) {
    writer.write(obj.toJson());
  }
}
