import 'package:get/get.dart';
import 'api.dart';
import '../../models/leaderboard_entry.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';

class LeaderboardService extends GetxController {
  final ApiClient apiClient = ApiClient();

  /// Fetch leaderboard for a specific competition
  Future<List<LeaderboardEntry>> getCompetitionLeaderboard(
    String deviceId,
    int competitionId,
  ) async {
    //  Uncomment when ready to use real API
    try {
      final response = await apiClient.get(
        '/app/competitions/$competitionId/leaderboard/entries/',
        queryParameters: {'device': deviceId},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
        } else if (data is Map && data.containsKey('results')) {
          return (data['results'] as List)
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
        }
        return [];
      } else {
        throw ApiException(
          response.data['detail'] ?? 'Failed to fetch competition leaderboard',
        );
      }
    } catch (e) {
      logger.e(e);
      throw ApiException('Failed to fetch competition leaderboard');
    }
  }

  /// Fetch leaderboard for a specific exam
  Future<List<LeaderboardEntry>> getExamLeaderboard(
    String deviceId,
    int examId,
  ) async {
    try {
      final response = await apiClient.get(
        '/app/exams/$examId/leaderboard/entries/',
        queryParameters: {'device': deviceId},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
        } else if (data is Map && data.containsKey('results')) {
          return (data['results'] as List)
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
        }
        return [];
      } else {
        throw ApiException(
          response.data['detail'] ?? 'Failed to fetch exam leaderboard',
        );
      }
    } catch (e) {
      logger.e(e);
      throw ApiException('Failed to fetch exam leaderboard');
    }
  }

  /// Fetch all available competitions for leaderboard selection
  Future<List<Map<String, dynamic>>> getAvailableCompetitions(
    String deviceId,
  ) async {
    // Uncomment when ready to use real API
    try {
      final response = await apiClient.get(
        '/app/competitions/',
        queryParameters: {'device': deviceId},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map(
                (e) => {
                  'id': e['id'],
                  'name': e['name'] ?? 'Unknown Competition',
                  'isClosed': e['is_closed'] ?? false,
                },
              )
              .toList();
        }
        return [];
      } else {
        throw ApiException(
          response.data['detail'] ?? 'Failed to fetch competitions',
        );
      }
    } catch (e) {
      logger.e(e);
      // Return empty list if API fails - user can still use exam leaderboard
      return [];
    }
  }
}
