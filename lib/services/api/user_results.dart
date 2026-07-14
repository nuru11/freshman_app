import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';

class UserResultsService {
  final ApiClient apiClient = ApiClient();

  Future<UserLeaderboardResult?> getUserLeaderboardResult(
    int competetionId,
  ) async {
    try {
      final response = await apiClient.get(
        '/app/competitions/$competetionId/user/stats/',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return UserLeaderboardResult.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // User hasn't attempted this competition
        return null;
      } else {
        logger.w('Unexpected status code: ${response.statusCode}');
        throw ApiException(
          response.data?['detail'] ?? 'Failed to fetch user results',
        );
      }
    } catch (e) {
      logger.e('Error fetching user results: $e');
      rethrow;
    }
  }
}
