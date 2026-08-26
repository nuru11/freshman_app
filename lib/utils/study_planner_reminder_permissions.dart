import 'dart:io' show Platform;

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_academy/components/ui/dialog/study_reminder_permission_dialogs.dart';
import 'package:vector_academy/services/notification_service.dart';
import 'package:vector_academy/utils/utils.dart';

/// In-context permission flow for study plan local notifications (not on cold start).
class StudyPlannerReminderPermissions {
  StudyPlannerReminderPermissions._();

  /// Shows rationale dialogs and requests OS permissions when appropriate.
  /// Call from [StudyPlannerController] when the user saves a plan — not from background sync.
  ///
  /// If notifications, exact alarms, or battery restrictions would block
  /// closed-app reminders, prompts on every save until they are granted.
  static Future<void> ensureBeforeScheduling() async {
    var ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) {
      logger.w('No overlay context for permission dialogs; skipping');
      return;
    }

    final notif = Get.find<LocalNotificationService>();

    if (!await notif.isNotificationAllowed()) {
      ctx = Get.overlayContext ?? Get.context;
      if (ctx == null || !ctx.mounted) return;
      final proceed =
          await StudyReminderPermissionDialogs.showNotificationRationale(ctx);
      if (proceed) {
        final granted = await notif.ensureNotificationPermission();
        if (!granted && !await notif.isNotificationAllowed()) {
          ctx = Get.overlayContext ?? Get.context;
          if (ctx != null && ctx.mounted) {
            final openSettings =
                await StudyReminderPermissionDialogs.showNotificationSettingsPrompt(
                  ctx,
                );
            if (openSettings) {
              await openAppSettings();
            }
          }
        }
      }
    }

    if (!Platform.isAndroid) return;
    if (!await notif.isNotificationAllowed()) return;

    if (!await notif.isExactAlarmGranted()) {
      ctx = Get.overlayContext ?? Get.context;
      if (ctx == null || !ctx.mounted) return;
      final openSettings =
          await StudyReminderPermissionDialogs.showExactAlarmRationale(ctx);
      if (openSettings) {
        await notif.requestExactAlarmPermission();
      }
    }

    if (!await notif.isBatteryUnrestricted()) {
      ctx = Get.overlayContext ?? Get.context;
      if (ctx == null || !ctx.mounted) return;
      final allow =
          await StudyReminderPermissionDialogs.showBatteryOptimizationRationale(
            ctx,
          );
      if (allow) {
        await notif.requestIgnoreBatteryOptimizations();
      }
    }
  }
}

