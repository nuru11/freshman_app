import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_academy/models/models.dart';
part 'subject.g.dart';

@JsonSerializable()
class Subject {
  final int id;
  final String name;
  final String? icon;
  final String? description;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'is_locked')
  final bool isLocked;

  final List<Chapter> chapters;

  Subject({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.chapters = const [],
    this.isLocked = true,
  });

  factory Subject.fromJson(Map<String, dynamic> json) =>
      _$SubjectFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectToJson(this);
}

class SubjectTypeAdapter implements TypeAdapter<Subject> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    return Subject(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      chapters: (json['chapters'] as List).cast<Chapter>(),
      isLocked: json['is_locked'] ?? true,
    );
  }

  @override
  int get typeId => 7;

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer.write(obj.toJson());
  }
}
