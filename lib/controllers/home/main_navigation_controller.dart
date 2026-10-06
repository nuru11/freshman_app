import 'package:get/get.dart';
import 'package:vector_academy/controllers/misc/user_score_controller.dart';

class MainNavigationController extends GetxController {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changeIndex(int index) {
    if (index >= 0 && index < 5) {
      // 5 tabs: Home, My Courses, Exam, Study Planner, Profile
      final openedHome = index == 0 && _currentIndex != 0;
      _currentIndex = index;
      update();
      if (openedHome && Get.isRegistered<UserScoreController>()) {
        Get.find<UserScoreController>().refreshHomeScoresIfNeeded();
      }
    }
  }
}
