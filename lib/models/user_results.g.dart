// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompetetionExam _$CompetetionExamFromJson(Map<String, dynamic> json) =>
    CompetetionExam(
      examName: json['exam_name'] as String,
      score: (json['score'] as num).toDouble(),
      totalQuestions: (json['total_questions'] as num).toInt(),
    );

Map<String, dynamic> _$CompetetionExamToJson(CompetetionExam instance) =>
    <String, dynamic>{
      'exam_name': instance.examName,
      'score': instance.score,
      'total_questions': instance.totalQuestions,
    };

UserLeaderboardResult _$UserLeaderboardResultFromJson(
  Map<String, dynamic> json,
) => UserLeaderboardResult(
  totalScore: (json['total_score'] as num).toDouble(),
  competetionName: json['competition_name'] as String,
  hasUserAttempted: json['has_user_attempted'] as bool,
  exams: (json['exams'] as List<dynamic>)
      .map((e) => CompetetionExam.fromJson(e as Map<String, dynamic>))
      .toList(),
  competitionId: (json['competition_id'] as num).toInt(),
  averageScore: (json['average_score'] as num).toDouble(),
  totalQuestions: (json['total_questions'] as num).toInt(),
);

Map<String, dynamic> _$UserLeaderboardResultToJson(
  UserLeaderboardResult instance,
) => <String, dynamic>{
  'total_score': instance.totalScore,
  'competition_name': instance.competetionName,
  'has_user_attempted': instance.hasUserAttempted,
  'exams': instance.exams,
  'competition_id': instance.competitionId,
  'total_questions': instance.totalQuestions,
  'average_score': instance.averageScore,
};
