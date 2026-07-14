// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exam _$ExamFromJson(Map<String, dynamic> json) => Exam(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  examType: json['exam_type'] as String,
  year: json['year'] as String?,
  totalQuestions: (json['total_questions'] as num?)?.toInt(),
  duration: (json['given_time_in_minutes'] as num).toInt(),
  isLocked: json['is_locked'] as bool,
  subject: json['subject'] == null
      ? null
      : Subject.fromJson(json['subject'] as Map<String, dynamic>),
  image: json['image'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  isDownloaded: json['is_downloaded'] as bool? ?? false,
  questions:
      (json['questions'] as List<dynamic>?)
          ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  modeType: json['mode_type'] as String? ?? 'both',
);

Map<String, dynamic> _$ExamToJson(Exam instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'exam_type': instance.examType,
  'year': instance.year,
  'total_questions': instance.totalQuestions,
  'given_time_in_minutes': instance.duration,
  'is_locked': instance.isLocked,
  'subject': instance.subject,
  'image': instance.image,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'mode_type': instance.modeType,
  'is_downloaded': instance.isDownloaded,
  'questions': instance.questions,
};
