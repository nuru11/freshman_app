import 'package:get/get.dart';
import 'package:vector_academy/services/premium_service.dart';
import 'package:vector_academy/views/study_hub/upgrade_premium_dialog.dart';

class StudyHubController extends GetxController {
  static const tabLabels = ['Planner', 'Pomodoro', 'Reading Plan', 'Challenge'];

  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  Future<void> selectTab(int index) async {
    if (index == _tabIndex) return;
    if (index > 0) {
      final premium = Get.find<PremiumService>();
      if (!premium.isPremium) {
        final names = ['Pomodoro', 'Reading Plan', 'Challenge'];
        await showUpgradeToPremiumDialog(feature: names[index - 1]);
        return;
      }
    }
    _tabIndex = index;
    update();
  }
}
