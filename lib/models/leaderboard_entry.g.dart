// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      userName: json['user_name'] as String,
      userImage: json['user_image'] as String?,
      score: (json['score'] as num).toDouble(),
      examId: (json['exam_id'] as num?)?.toInt(),
      examName: json['exam_name'] as String?,
      competitionId: (json['competition_id'] as num?)?.toInt(),
      competitionName: json['competition_name'] as String?,
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'user_id': instance.userId,
      'user_name': instance.userName,
      'user_image': instance.userImage,
      'score': instance.score,
      'exam_id': instance.examId,
      'exam_name': instance.examName,
      'competition_id': instance.competitionId,
      'competition_name': instance.competitionName,
    };
