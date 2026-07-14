// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
  id: (json['id'] as num).toInt(),
  chapterNumber: (json['chapter_number'] as num).toInt(),
  subject: (json['subject'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  notes: json['notes'] as List<dynamic>? ?? const [],
  quizzes: json['quizzes'] as List<dynamic>? ?? const [],
  videos: json['videos'] as List<dynamic>? ?? const [],
);

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'chapter_number': instance.chapterNumber,
  'subject': instance.subject,
  'name': instance.name,
  'description': instance.description,
  'notes': instance.notes,
  'quizzes': instance.quizzes,
  'videos': instance.videos,
};
