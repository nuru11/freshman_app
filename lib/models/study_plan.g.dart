// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudyPlan _$StudyPlanFromJson(Map<String, dynamic> json) => StudyPlan(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  subject: json['subject'] as String,
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  completedDates:
      (json['completed_dates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  repeatDays:
      (json['repeat_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
);

Map<String, dynamic> _$StudyPlanToJson(StudyPlan instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'subject': instance.subject,
  'due_date': ?instance.dueDate?.toIso8601String(),
  'start_date': ?instance.startDate?.toIso8601String(),
  'end_date': ?instance.endDate?.toIso8601String(),
  'completed_dates': instance.completedDates,
  'created_at': instance.createdAt.toIso8601String(),
  'repeat_days': instance.repeatDays,
};
