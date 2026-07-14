import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vector_academy/models/models.dart';

part 'competetion.g.dart';

@JsonSerializable()
class Competetion {
  final int id;
  final String name;
  final String description;
  final List<Exam> exams;

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isClosed;

  Competetion({
    required this.id,
    required this.name,
    this.description = '',
    required this.exams,
    required this.createdAt,
    required this.updatedAt,
    this.isClosed = false,
  });

  factory Competetion.fromJson(Map<String, dynamic> json) =>
      _$CompetetionFromJson(json);
  Map<String, dynamic> toJson() => _$CompetetionToJson(this);
}

class CompetetionTypeAdapter implements TypeAdapter<Competetion> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    return Competetion.fromJson(json_);
  }

  @override
  int get typeId => 17;

  @override
  void write(BinaryWriter writer, Competetion obj) {
    writer.write(obj.toJson());
  }
}
