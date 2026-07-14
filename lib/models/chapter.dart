import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

@JsonSerializable()
class Chapter {
  final int id;
  @JsonKey(name: 'chapter_number')
  final int chapterNumber;
  final int subject;
  final String name;
  final String? description;
  final List notes;
  final List quizzes;
  final List videos;

  Chapter({
    required this.id,
    required this.chapterNumber,
    required this.subject,
    required this.name,
    required this.description,
    this.notes = const [],
    this.quizzes = const [],
    this.videos = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterToJson(this);
}

class ChapterTypeAdapter implements TypeAdapter<Chapter> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    return Chapter(
      id: json['id'],
      chapterNumber: json['chapterNumber'] ?? 1,
      subject: json['subject'] ?? 1,
      name: json['name'],
      description: json['description'],
      notes: json['notes'] ?? [],
      quizzes: json['quizzes'] ?? [],
      videos: json['videos'] ?? [],
    );
  }

  @override
  int get typeId => 1;

  @override
  void write(BinaryWriter writer, Chapter obj) {
    writer.write(obj.toJson());
  }
}
