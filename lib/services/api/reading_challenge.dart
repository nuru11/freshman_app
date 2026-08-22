import 'package:get/get.dart';
import 'package:vector_academy/models/reading_premium.dart';
import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';

class ReadingChallengeService extends GetxController {
  final ApiClient apiClient = ApiClient();

  Future<List<ReadingChallenge>> listChallenges() async {
    try {
      final response = await apiClient.get(
        '/app/reading-challenges/',
        authenticated: true,
      );
      if (response.statusCode == 403) return [];
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => ReadingChallenge.fromJson(e))
            .toList();
      }
      throw ApiException(
        ApiErrorMessage.fromData(response.data) ??
            'Failed to load reading challenges',
      );
    } catch (e) {
      logger.e('Error loading challenges: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load reading challenges');
    }
  }

  Future<ReadingChallenge> join(int id) async {
    final response = await apiClient.post(
      '/app/reading-challenges/$id/join/',
      authenticated: true,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReadingChallenge.fromJson(response.data);
    }
    throw ApiException(
      ApiErrorMessage.fromData(response.data) ?? 'Failed to join challenge',
    );
  }

  Future<ReadingChallenge> setAlarm(int id, bool enabled) async {
    final response = await apiClient.post(
      '/app/reading-challenges/$id/alarm/',
      data: {'enabled': enabled},
      authenticated: true,
    );
    if (response.statusCode == 200) {
      return ReadingChallenge.fromJson(response.data);
    }
    throw ApiException(
      ApiErrorMessage.fromData(response.data) ?? 'Failed to update alarm',
    );
  }
}
