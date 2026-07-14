import 'package:json_annotation/json_annotation.dart';

part 'user_results.g.dart';

@JsonSerializable()
class CompetetionExam {
  @JsonKey(name: "exam_name")
  final String examName;
  final double score;
  @JsonKey(name: "total_questions")
  final int totalQuestions;
  CompetetionExam({
    required this.examName,
    required this.score,
    required this.totalQuestions,
  });
  factory CompetetionExam.fromJson(Map<String, dynamic> json) {
    // Safe parsing with validation
    final scoreValue = json['score'];
    final totalQuestionsValue = json['total_questions'];

    // Handle score safely
    double safeScore = 0.0;
    if (scoreValue != null) {
      if (scoreValue is num) {
        final doubleValue = scoreValue.toDouble();
        safeScore = doubleValue.isFinite ? doubleValue : 0.0;
      }
    }

    // Handle total_questions safely
    int safeTotalQuestions = 0;
    if (totalQuestionsValue != null) {
      if (totalQuestionsValue is int) {
        safeTotalQuestions = totalQuestionsValue;
      } else if (totalQuestionsValue is num) {
        final doubleValue = totalQuestionsValue.toDouble();
        safeTotalQuestions = doubleValue.isFinite ? doubleValue.toInt() : 0;
      }
    }

    return CompetetionExam(
      examName: json['exam_name'] as String? ?? 'Unknown Exam',
      score: safeScore,
      totalQuestions: safeTotalQuestions,
    );
  }
  Map<String, dynamic> toJson() => _$CompetetionExamToJson(this);
}

@JsonSerializable()
class UserLeaderboardResult {
  @JsonKey(name: "total_score")
  final double totalScore;
  @JsonKey(name: "competition_name")
  final String competetionName;
  @JsonKey(name: "has_user_attempted")
  final bool hasUserAttempted;
  final List<CompetetionExam> exams;
  @JsonKey(name: "competition_id")
  final int competitionId;

  @JsonKey(name: "total_questions")
  final int totalQuestions;

  @JsonKey(name: "average_score")
  final double averageScore;

  UserLeaderboardResult({
    required this.totalScore,
    required this.competetionName,
    required this.hasUserAttempted,
    required this.exams,
    required this.competitionId,
    required this.averageScore,
    required this.totalQuestions,
  });
  factory UserLeaderboardResult.fromJson(Map<String, dynamic> json) {
    // Safe parsing with validation
    final totalScoreValue = json['total_score'];
    final competitionIdValue = json['competition_id'];

    // Handle total_score safely
    double safeTotalScore = 0.0;
    if (totalScoreValue != null) {
      if (totalScoreValue is num) {
        final doubleValue = totalScoreValue.toDouble();
        safeTotalScore = doubleValue.isFinite ? doubleValue : 0.0;
      }
    }

    // Handle competition_id safely
    int safeCompetitionId = 0;
    if (competitionIdValue != null) {
      if (competitionIdValue is int) {
        safeCompetitionId = competitionIdValue;
      } else if (competitionIdValue is num) {
        final doubleValue = competitionIdValue.toDouble();
        safeCompetitionId = doubleValue.isFinite ? doubleValue.toInt() : 0;
      }
    }

    // Parse exams list safely
    List<CompetetionExam> safeExams = [];
    if (json['exams'] is List) {
      final examsList = json['exams'] as List;
      for (var examJson in examsList) {
        try {
          if (examJson is Map<String, dynamic>) {
            safeExams.add(CompetetionExam.fromJson(examJson));
          }
        } catch (e) {
          // Skip invalid exam entries
          continue;
        }
      }
    }

    return UserLeaderboardResult(
      totalScore: safeTotalScore,
      competetionName:
          json['competition_name'] as String? ?? 'Unknown Competition',
      hasUserAttempted: json['has_user_attempted'] as bool? ?? false,
      exams: safeExams,
      competitionId: safeCompetitionId,
      averageScore: json['average_score'] as double? ?? 0.0,
      totalQuestions: json['total_questions'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() => _$UserLeaderboardResultToJson(this);
}
