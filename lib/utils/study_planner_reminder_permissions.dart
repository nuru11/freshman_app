import 'dart:io' show Platform;

import 'package:get/get.dart';
import 'package:vector_academy/components/ui/dialog/study_reminder_permission_dialogs.dart';
import 'package:vector_academy/services/notification_service.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/utils.dart';

/// In-context permission flow for study plan local notifications (not on cold start).
class StudyPlannerReminderPermissions {
  StudyPlannerReminderPermissions._();

  /// Shows rationale dialogs and requests OS permissions when appropriate.
  /// Call from [StudyPlannerController] when the user saves a plan — not from background sync.
  static Future<void> ensureBeforeScheduling() async {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) {
      logger.w('No overlay context for permission dialogs; skipping');
      return;
    }

    final notif = Get.find<LocalNotificationService>();

    if (!ConfigPreference.hasAskedStudyPlanNotificationPermission()) {
      final proceed = await StudyReminderPermissionDialogs.showNotificationRationale(
        context,
      );
      await ConfigPreference.setAskedStudyPlanNotificationPermission(true);
      if (proceed) {
        await notif.ensureNotificationPermission();
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
