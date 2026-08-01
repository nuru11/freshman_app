import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';

enum _SnackbarKind { success, error, warning, info }

class AppSnackbar {
  static void _closeExisting() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
  }

  static void _show(
    _SnackbarKind kind,
    String title,
    String message, {
    Duration? duration,
  }) {
    _closeExisting();

    final Color backgroundColor;
    final IconData icon;
    final Duration defaultDuration;

    switch (kind) {
      case _SnackbarKind.success:
        backgroundColor = successColor;
        icon = Icons.check_circle;
        defaultDuration = const Duration(seconds: 3);
        break;
      case _SnackbarKind.error:
        backgroundColor = errorColor;
        icon = Icons.error;
        defaultDuration = const Duration(seconds: 4);
        break;
      case _SnackbarKind.warning:
        backgroundColor = warningColor;
        icon = Icons.warning;
        defaultDuration = const Duration(seconds: 3);
        break;
      case _SnackbarKind.info:
        backgroundColor = infoColor;
        icon = Icons.info;
        defaultDuration = const Duration(seconds: 3);
        break;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: duration ?? defaultDuration,
      icon: Icon(icon, color: Colors.white),
    );
  }

  static void _showAfterFrame(
    void Function() show, {
    Duration delay = Duration.zero,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (delay == Duration.zero) {
        show();
        return;
      }
      Future.delayed(delay, show);
    });
  }

  static void showSuccess(String title, String message, {Duration? duration}) {
    _show(_SnackbarKind.success, title, message, duration: duration);
  }

  static void showError(String title, String message, {Duration? duration}) {
    _show(_SnackbarKind.error, title, message, duration: duration);
  }

  static void showWarning(String title, String message, {Duration? duration}) {
    _show(_SnackbarKind.warning, title, message, duration: duration);
  }

  static void showInfo(String title, String message, {Duration? duration}) {
    _show(_SnackbarKind.info, title, message, duration: duration);
  }

  /// Show after the next frame so the snackbar survives route changes
  /// (`Get.offAllNamed`, `Get.back`, etc.).
  static void showSuccessAfterNav(
    String title,
    String message, {
    Duration? duration,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    _showAfterFrame(
      () => showSuccess(title, message, duration: duration),
      delay: delay,
    );
  }

  static void showErrorAfterNav(
    String title,
    String message, {
    Duration? duration,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    _showAfterFrame(
      () => showError(title, message, duration: duration),
      delay: delay,
    );
  }

  static void showWarningAfterNav(
    String title,
    String message, {
    Duration? duration,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    _showAfterFrame(
      () => showWarning(title, message, duration: duration),
      delay: delay,
    );
  }

  static void showInfoAfterNav(
    String title,
    String message, {
    Duration? duration,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    _showAfterFrame(
      () => showInfo(title, message, duration: duration),
      delay: delay,
    );
  }

  static void showLoading(String title, String message) {
    _closeExisting();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: primaryColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(days: 1),
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.white,
      icon: const Icon(Icons.hourglass_empty, color: Colors.white),
    );
  }
}
