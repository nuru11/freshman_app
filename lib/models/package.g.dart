// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Package _$PackageFromJson(Map<String, dynamic> json) => Package(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  durationDays: (json['duration_days'] as num).toInt(),
  exams: (json['exams'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  subjects: (json['subjects'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  grade: (json['grade'] as num?)?.toInt(),
  isLocked: json['is_locked'] as bool,
);

Map<String, dynamic> _$PackageToJson(Package instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'duration_days': instance.durationDays,
  'exams': instance.exams,
  'subjects': instance.subjects,
  'grade': instance.grade,
  'is_locked': instance.isLocked,
};
