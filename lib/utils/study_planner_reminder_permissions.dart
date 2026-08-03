import 'dart:io' show Platform;

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_academy/components/ui/dialog/study_reminder_permission_dialogs.dart';
import 'package:vector_academy/services/notification_service.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/utils.dart';

/// In-context permission flow for study plan local notifications (not on cold start).
class StudyPlannerReminderPermissions {
  StudyPlannerReminderPermissions._();

  /// Shows rationale dialogs and requests OS permissions when appropriate.
  /// Call from [StudyPlannerController] when the user saves a plan — not from background sync.
  ///
  /// If notifications are disabled, prompts on every save until the user enables them.
  static Future<void> ensureBeforeScheduling() async {
    if (Get.overlayContext == null && Get.context == null) {
      logger.w('No overlay context for permission dialogs; skipping');
      return;
    }

    final notif = Get.find<LocalNotificationService>();

    if (!await notif.isNotificationAllowed()) {
      final ctxForNotif = Get.overlayContext ?? Get.context;
      if (ctxForNotif == null || !ctxForNotif.mounted) return;
      final proceed =
          await StudyReminderPermissionDialogs.showNotificationRationale(
            ctxForNotif,
          );
      if (proceed) {
        final granted = await notif.ensureNotificationPermission();
        if (!granted && !await notif.isNotificationAllowed()) {
          final ctxForSettings = Get.overlayContext ?? Get.context;
          if (ctxForSettings != null && ctxForSettings.mounted) {
            final openSettings =
                await StudyReminderPermissionDialogs.showNotificationSettingsPrompt(
                  ctxForSettings,
                );
            if (openSettings) {
              await openAppSettings();
            }
          }
        }
      }
    }

    if (Platform.isAndroid &&
        !ConfigPreference.hasAskedStudyPlanExactAlarmPermission()) {
      if (await notif.isNotificationAllowed()) {
        final ctxForExact = Get.overlayContext ?? Get.context;
        if (ctxForExact == null || !ctxForExact.mounted) return;
        final openSettings =
            await StudyReminderPermissionDialogs.showExactAlarmRationale(
              ctxForExact,
            );
        await ConfigPreference.setAskedStudyPlanExactAlarmPermission(true);
        if (openSettings) {
          await notif.requestExactAlarmPermission();
        }
      }
    }
  }
}
