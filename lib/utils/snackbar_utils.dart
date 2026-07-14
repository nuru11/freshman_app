import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';

class AppSnackbar {
  static void showSuccess(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: successColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: EdgeInsets.all(16),
      duration: duration ?? Duration(seconds: 3),
      icon: Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void showError(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: errorColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: EdgeInsets.all(16),
      duration: duration ?? Duration(seconds: 4),
      icon: Icon(Icons.error, color: Colors.white),
    );
  }

  static void showWarning(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: warningColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: EdgeInsets.all(16),
      duration: duration ?? Duration(seconds: 3),
      icon: Icon(Icons.warning, color: Colors.white),
    );
  }

  static void showInfo(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: infoColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: EdgeInsets.all(16),
      duration: duration ?? Duration(seconds: 3),
      icon: Icon(Icons.info, color: Colors.white),
    );
  }

  static void showLoading(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: primaryColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: EdgeInsets.all(16),
      duration: Duration(days: 1),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.white,
      icon: Icon(Icons.hourglass_empty, color: Colors.white),
    );
  }
}
