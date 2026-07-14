import 'package:flutter/material.dart';

/// In-app rationale before system notification / exact-alarm prompts for study plans.
class StudyReminderPermissionDialogs {
  StudyReminderPermissionDialogs._();

  /// `true` if the user chose **Allow** (proceed to OS notification prompt).
  static Future<bool> showNotificationRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Study plan reminders'),
        content: const Text(
          'Allow notifications so we can remind you about your study plans at the times you choose.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// `true` if the user chose **Open settings** (exact alarm / Alarms & reminders).
  static Future<bool> showExactAlarmRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Precise reminder times'),
        content: const Text(
          'For reminders exactly on schedule, Android needs "Alarms & reminders" access. You can skip this and still get reminders that may be a few minutes off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
