import 'package:get/get.dart';
import 'package:vector_academy/services/auth.dart';
import 'package:vector_academy/utils/home_tab_controllers.dart';
import 'package:vector_academy/views/views.dart';

const String authReturnRouteKey = 'returnRoute';
const String authCheckoutArgsKey = 'checkoutArgs';

bool get isCurrentUserAuthenticated =>
    Get.isRegistered<AuthService>() &&
    Get.find<AuthService>().isAuthenticated;

bool requireAuth({
  String? returnRoute,
  Map<String, dynamic>? returnArgs,
  bool replace = false,
}) {
  if (Get.isRegistered<AuthService>() &&
      Get.find<AuthService>().isAuthenticated) {
    return true;
  }

  final arguments = {
    authReturnRouteKey: returnRoute,
    authCheckoutArgsKey: returnArgs,
  };
  if (replace) {
    Get.offNamed(VIEWS.register.path, arguments: arguments);
  } else {
    Get.toNamed(VIEWS.register.path, arguments: arguments);
  }
  return false;
}

bool requireAuthForPurchase({
  Map<String, dynamic>? checkoutArgs,
  bool replace = false,
}) {
  return requireAuth(
    returnRoute: VIEWS.payments.path,
    returnArgs: checkoutArgs,
    replace: replace,
  );
}

Map<String, dynamic>? captureAuthRedirectArgs([dynamic rawArgs]) {
  final args = rawArgs ?? Get.arguments;
  if (args is Map) {
    return Map<String, dynamic>.from(args);
  }
  return null;
}

void navigateAfterAuth([Map<String, dynamic>? redirectArgs]) {
  final args = redirectArgs ?? captureAuthRedirectArgs();
  final returnRoute = args?[authReturnRouteKey] as String?;
  final checkoutArgs = args?[authCheckoutArgsKey];

  clearHomeTabControllers();
  Get.offAllNamed(VIEWS.home.path);
  if (returnRoute != null && returnRoute.isNotEmpty) {
    Future.microtask(() {
      Get.toNamed(returnRoute, arguments: checkoutArgs);
    });
  }
}
