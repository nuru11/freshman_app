import 'package:get/get.dart';
import 'package:vector_academy/services/api/user.dart';
import 'package:vector_academy/services/auth.dart';
import 'package:vector_academy/utils/access_override.dart';
import 'package:vector_academy/views/study_hub/upgrade_premium_dialog.dart';

class PremiumService extends GetxService {
  AuthService get _auth {
    return Get.find<AuthService>();
  }

  bool get isPremium {
    final user = _auth.user.value;
    if (user == null) return false;
    if (hasFullAccessOverrideForPhone(user.phoneNumber)) return true;
    return user.isPremium;
  }

  @override
  void onInit() {
    super.onInit();
    refreshFromServer();
  }

  Future<void> refreshFromServer() async {
    try {
      if (!_auth.isAuthenticated) return;
      final user = await UserService().getUser();
      await _auth.saveUser(user);
    } catch (_) {}
  }

  /// Returns true if the user may use the feature. Otherwise shows the paywall.
  Future<bool> ensurePremium({String feature = 'this feature'}) async {
    if (isPremium) return true;
    await refreshFromServer();
    if (isPremium) return true;
    await showUpgradeToPremiumDialog(feature: feature);
    return false;
  }
}
