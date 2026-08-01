import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';

enum _SnackbarKind { success, error, warning, info }

class AppSnackbar {
  static void _closeExisting() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    } catch (_) {
      // Ignore close failures so they never block showing a new message.
    }

    try {
      final ctx = _messengerContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      }
    } catch (_) {
      // Ignore messenger close failures.
    }
  }

  static BuildContext? get _messengerContext =>
      Get.overlayContext ?? Get.context ?? Get.key.currentContext;

  static void _showScaffoldFallback({
    required String title,
    required String message,
    required Color backgroundColor,
    required Duration duration,
  }) {
    final ctx = _messengerContext;
    if (ctx == null) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          '$title\n$message',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  static void _showNow(
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

    final effectiveDuration = duration ?? defaultDuration;

    try {
      if (_messengerContext == null) {
        _showScaffoldFallback(
          title: title,
          message: message,
          backgroundColor: backgroundColor,
          duration: effectiveDuration,
        );
        return;
      }

      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: effectiveDuration,
        icon: Icon(icon, color: Colors.white),
      );
    } catch (_) {
      _showScaffoldFallback(
        title: title,
        message: message,
        backgroundColor: backgroundColor,
        duration: effectiveDuration,
      );
    }
  }

  static void _show(
    _SnackbarKind kind,
    String title,
    String message, {
    Duration? duration,
  }) {
    _showAfterFrame(
      () => _showNow(kind, title, message, duration: duration),
    );
  }

  static void _showAfterFrame(
    void Function() show, {
    Duration delay = Duration.zero,
  }) {
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle) {
      // Already between frames; still defer to next frame so overlay is ready.
      scheduler.addPostFrameCallback((_) {
        if (delay == Duration.zero) {
          show();
          return;
        }
        Future.delayed(delay, show);
      });
      // Force a frame if nothing else is scheduled.
      scheduler.scheduleFrame();
      return;
    }

    scheduler.addPostFrameCallback((_) {
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
      () => _showNow(_SnackbarKind.success, title, message, duration: duration),
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
      () => _showNow(_SnackbarKind.error, title, message, duration: duration),
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
      () => _showNow(_SnackbarKind.warning, title, message, duration: duration),
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
      () => _showNow(_SnackbarKind.info, title, message, duration: duration),
      delay: delay,
    );
  }

  static void showLoading(String title, String message) {
    _showAfterFrame(() {
      _closeExisting();
      try {
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
      } catch (_) {
        _showScaffoldFallback(
          title: title,
          message: message,
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 4),
        );
      }
    });
  }
}
