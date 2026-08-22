// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudyPlanAlarm _$StudyPlanAlarmFromJson(Map<String, dynamic> json) =>
    StudyPlanAlarm(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      offsetMinutes: (json['offset_minutes'] as num?)?.toInt() ?? 15,
      sound: json['sound'] as String? ?? 'default',
      vibration: json['vibration'] as String? ?? 'default',
      snoozeMinutes: (json['snooze_minutes'] as num?)?.toInt() ?? 5,
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$StudyPlanAlarmToJson(StudyPlanAlarm instance) =>
    <String, dynamic>{
      'id': instance.id,
      'offset_minutes': instance.offsetMinutes,
      'sound': instance.sound,
      'vibration': instance.vibration,
      'snooze_minutes': instance.snoozeMinutes,
      'enabled': instance.enabled,
    };

StudyPlan _$StudyPlanFromJson(Map<String, dynamic> json) => StudyPlan(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  subject: json['subject'] as String? ?? '',
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
  createdAt: json['created_at'] == null
      ? DateTime.now()
      : DateTime.parse(json['created_at'] as String),
  repeatDays:
      (json['repeat_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  alarmsEnabled: json['alarms_enabled'] as bool? ?? true,
  alarms:
      (json['alarms'] as List<dynamic>?)
          ?.map((e) => StudyPlanAlarm.fromJson(Map<String, dynamic>.from(e as Map)))
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
  'alarms_enabled': instance.alarmsEnabled,
  'alarms': instance.alarms.map((e) => e.toJson()).toList(),
};
