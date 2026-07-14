import 'package:get/get.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/views.dart';

class SuccessStoriesController extends GetxController {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<SuccessStory> _stories = [];
  List<SuccessStory> get stories => _stories;
  List<SuccessStory> _allStories = [];
  SuccessStory? featuredStory;
  int selectedCategoryIndex = 0;
  List<String> categories = [];

  void setSelectedCategoryIndex(int index) {
    selectedCategoryIndex = index;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadStories();
  }

  Future<void> loadStories() async {
    _isLoading = true;
    update();

    try {
      _stories = await SuccessStoriesService().getSuccessStories();
      _allStories = _stories;
      if (_allStories.isNotEmpty) {
        featuredStory = _allStories.first;
        categories = _allStories.map((e) => e.category.name).toSet().toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load success stories');
      logger.e(e);
    } finally {
      _isLoading = false;
      update();
    }
  }

  void openStoryDetail(int storyId) {
    try {
      final story = _stories.firstWhere((s) => s.id == storyId);
      Get.toNamed(VIEWS.successStoryDetail.path, arguments: story);
    } catch (e) {
      // If story not found in current list, navigate with ID
      Get.toNamed('${VIEWS.successStoryDetail.path}?id=$storyId');
    }
  }

  void changeCategory(int index) {
    selectedCategoryIndex = index;
    if (index == 0) {
      _stories = _allStories;
    } else {
      // Index 0 is "All", so we need to subtract 1 to get the actual category index
      final category = categories[index - 1];
      _stories = _allStories.where((s) => s.category.name == category).toList();
    }
    update();
  }

  void refreshStories() {
    loadStories();
  }

  Future<List<SuccessStory>> searchStories(String query) async {
    final lowerQuery = query.toLowerCase();
    return _stories
        .where(
          (s) =>
              s.title.toLowerCase().contains(lowerQuery) ||
              (s.studentName != null &&
                  s.studentName!.toLowerCase().contains(lowerQuery)) ||
              (s.achievement != null &&
                  s.achievement!.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }
}
