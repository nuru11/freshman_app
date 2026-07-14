import 'package:flutter/material.dart';
import 'package:get/get.dart';

const String _homeRoutePath = '/home';

/// Pops the current route using the route [context] first (matches iOS swipe-back),
/// with GetX fallback and home fallback.
void safePop({required BuildContext context, Object? result}) {
  if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
    Get.back(result: result);
    return;
  }

  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop(result);
    return;
  }

  final nav = Get.key.currentState;
  if (nav != null && nav.canPop()) {
    Get.back(result: result);
    return;
  }

  if (Get.currentRoute != _homeRoutePath) {
    Get.offAllNamed(_homeRoutePath);
  }
}
