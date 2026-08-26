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
          'Allow notifications so we can remind you at study time even if the '
          'app is closed or you are asleep.',
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

  /// `true` if the user chose **Open settings** (app notification settings).
  static Future<bool> showNotificationSettingsPrompt(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable notifications'),
        content: const Text(
          'Notifications are still off. Open settings to enable them so we can '
          'remind you about your study plans when the app is closed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
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

  /// `true` if the user chose **Open settings** (exact alarm / Alarms & reminders).
  static Future<bool> showExactAlarmRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminders when the app is closed'),
        content: const Text(
          'For reminders at the exact time — even after you leave the app or '
          'are asleep — Android needs "Alarms & reminders" access.',
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

  /// `true` if the user chose **Allow** (battery unrestricted).
  static Future<bool> showBatteryOptimizationRationale(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Allow background reminders'),
        content: const Text(
          'Some phones pause reminders after you swipe the app away. Allow '
          'unrestricted battery so we can wake you at study time, even if you '
          'are asleep.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Skip'),
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
}
