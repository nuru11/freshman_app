// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competetion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Competetion _$CompetetionFromJson(Map<String, dynamic> json) => Competetion(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  exams: (json['exams'] as List<dynamic>)
      .map((e) => Exam.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isClosed: json['isClosed'] as bool? ?? false,
);

Map<String, dynamic> _$CompetetionToJson(Competetion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'exams': instance.exams,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isClosed': instance.isClosed,
    };
