import 'package:get/get.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/utils.dart';

class NavigationDrawerController extends GetxController {
  bool _isDrawerOpen = false;
  bool get isDrawerOpen => _isDrawerOpen;

  void toggleDrawer() {
    _isDrawerOpen = !_isDrawerOpen;
    update();
  }

  void closeDrawer() {
    _isDrawerOpen = false;
    update();
  }

  void openDrawer() {
    _isDrawerOpen = true;
    update();
  }

  // Navigation methods for drawer items
  void navigateToFAQ() {
    AppSnackbar.showInfo('Info', 'FAQ page will be implemented');
    closeDrawer();
  }

  void navigateToSupport() {
    AppSnackbar.showInfo('Info', 'Support page will be implemented');
    closeDrawer();
  }

  void navigateToAbout() {
    AppSnackbar.showInfo('Info', 'About page will be implemented');
    closeDrawer();
  }

  void navigateToContactUs() {
    AppSnackbar.showInfo('Info', 'Contact Us page will be implemented');
    closeDrawer();
  }

  void logout() async {
    // Navigate to login and clear navigation stack
    await AuthService().logout();
    Get.offAllNamed(VIEWS.login.path);
  }
}
