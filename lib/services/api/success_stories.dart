import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'api.dart';

class SuccessStoriesService {
  final _apiClient = ApiClient();

  Future<List<SuccessStory>> getSuccessStories() async {
    final response = await _apiClient.get(
      '/app/success-stories',
      authenticated: false,
    );
    return (response.data as List)
        .map((e) => SuccessStory.fromJson(e))
        .toList();
  }

  Future<SuccessStory?> getSuccessStoryById(int storyId) async {
    try {
      final response = await _apiClient.get(
        '/app/success-stories/$storyId/',
        authenticated: false,
      );
      logger.f('response: ${response.data}');
      if (response.statusCode == 200) {
        return SuccessStory.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

