import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'api.dart';

class NewsService {
  final _apiClient = ApiClient();

  Future<List<News>> getNews() async {
    final response = await _apiClient.get('/app/news', authenticated: false);
    return (response.data as List).map((e) => News.fromJson(e)).toList();
  }

  Future<News?> getNewsById(int newsId) async {
    try {
      // final allNews = await getNews();
      // return allNews.firstWhere((news) => news.id == newsId);
      final response = await _apiClient.get(
        '/app/news/$newsId/',
        authenticated: false,
      );
      logger.f('response: ${response.data}');
      if (response.statusCode == 200) {
        return News.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
