import 'package:json_annotation/json_annotation.dart';

part 'leaderboard_entry.g.dart';

@JsonSerializable()
class LeaderboardEntry {
  final int rank;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'user_image')
  final String? userImage;
  final double score;
  @JsonKey(name: 'exam_id')
  final int? examId;
  @JsonKey(name: 'exam_name')
  final String? examName;
  @JsonKey(name: 'competition_id')
  final int? competitionId;
  @JsonKey(name: 'competition_name')
  final String? competitionName;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.score,
    this.examId,
    this.examName,
    this.competitionId,
    this.competitionName,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);
}
