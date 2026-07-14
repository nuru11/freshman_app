import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changeIndex(int index) {
    if (index >= 0 && index < 5) {
      // 5 tabs: Home, My Courses, News, Study Planner, Profile

      _currentIndex = index;
      update();
    }
  }
}
