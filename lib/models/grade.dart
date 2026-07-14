import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'grade.g.dart';

@JsonSerializable()
class Grade {
  final int id;
  final String name;

  Grade({required this.id, required this.name});

  factory Grade.fromJson(Map<String, dynamic> json) => _$GradeFromJson(json);
  Map<String, dynamic> toJson() => _$GradeToJson(this);
}

class GradeTypeAdapter implements TypeAdapter<Grade> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    return Grade(id: json['id'], name: json['name']);
  }

  @override
  int get typeId => 3;

  @override
  void write(BinaryWriter writer, Grade obj) {
    writer.write(obj.toJson());
  }
}
