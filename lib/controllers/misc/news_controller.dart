import 'package:get/get.dart';
import 'package:vector_academy/views/news/news_detail_page.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/utils/storages/storages.dart';

class NewsController extends GetxController {
  final HiveNewsStorage _newsStorage = HiveNewsStorage();
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isShowingOfflineData = false;
  bool get isShowingOfflineData => _isShowingOfflineData;

  List<News> _news = [];
  List<News> get news => _news;
  List<News> _allNews = [];
  News? featuredNews;
  int selectedCategoryIndex = 0;
  List<String> categories = [];

  void setSelectedCategoryIndex(int index) {
    selectedCategoryIndex = index;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadNews();
  }

  Future<void> loadNews() async {
    _isLoading = true;
    _isShowingOfflineData = false;
    update();

    try {
      final cachedNews = await _newsStorage.getNews();
      if (cachedNews.isNotEmpty) {
        _applyNewsData(cachedNews);
        update();
      }

      _news = await NewsService().getNews();
      _applyNewsData(_news);
      await _newsStorage.setNews(_news);
      _isShowingOfflineData = false;
    } catch (e) {
      final cachedNews = await _newsStorage.getNews();
      if (cachedNews.isNotEmpty) {
        _applyNewsData(cachedNews);
        _isShowingOfflineData = true;
      } else {
        Get.snackbar('Error', 'Failed to load news');
      }
      logger.e(e);
    } finally {
      _isLoading = false;
      update();
    }
  }

  void _applyNewsData(List<News> items) {
    _news = List<News>.from(items);
    _allNews = List<News>.from(items);
    if (_allNews.isNotEmpty) {
      featuredNews = _allNews.first;
      categories = ['All', ..._allNews.map((e) => e.category).toSet()];
      selectedCategoryIndex = 0;
      _news = _allNews;
    } else {
      featuredNews = null;
      categories = [];
    }
  }

  void openNewsDetail(int newsId) {
    final news = _news.firstWhere((n) => n.id == newsId);
    Get.to(() => NewsDetailPage(news: news));
  }

  void changeCategory(int index) {
    if (index < 0 || index >= categories.length) {
      return;
    }
    selectedCategoryIndex = index;
    final category = categories[index];
    if (category == 'All') {
      _news = _allNews;
    } else {
      _news = _allNews.where((n) => n.category == category).toList();
    }
    update();
  }

  void refreshNews() {
    loadNews();
  }

  Future<List<News>> searchNews(String query) async {
    return _news
        .where((n) => n.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
