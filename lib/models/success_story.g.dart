// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'success_story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuccessStoryCategory _$SuccessStoryCategoryFromJson(
  Map<String, dynamic> json,
) => SuccessStoryCategory(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$SuccessStoryCategoryToJson(
  SuccessStoryCategory instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

SuccessStory _$SuccessStoryFromJson(Map<String, dynamic> json) => SuccessStory(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String,
  image: json['image'] as String?,
  studentPhoto: json['student_photo'] as String?,
  studentName: json['student_name'] as String?,
  achievement: json['achievement'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  category: SuccessStoryCategory.fromJson(
    json['category'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SuccessStoryToJson(SuccessStory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'image': instance.image,
      'student_photo': instance.studentPhoto,
      'student_name': instance.studentName,
      'achievement': instance.achievement,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'category': instance.category,
    };
