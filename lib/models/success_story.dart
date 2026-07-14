import 'package:json_annotation/json_annotation.dart';

part 'success_story.g.dart';

@JsonSerializable()
class SuccessStoryCategory {
  final int id;
  final String name;

  SuccessStoryCategory({required this.id, required this.name});

  factory SuccessStoryCategory.fromJson(Map<String, dynamic> json) =>
      _$SuccessStoryCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$SuccessStoryCategoryToJson(this);
}

@JsonSerializable()
class SuccessStory {
  final int id;
  final String title;
  final String content;
  final String? image;

  @JsonKey(name: 'student_photo')
  final String? studentPhoto;

  @JsonKey(name: 'student_name')
  final String? studentName;

  final String? achievement;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  final SuccessStoryCategory category;

  SuccessStory({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.studentPhoto,
    this.studentName,
    this.achievement,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory SuccessStory.fromJson(Map<String, dynamic> json) =>
      _$SuccessStoryFromJson(json);
  Map<String, dynamic> toJson() => _$SuccessStoryToJson(this);
}
