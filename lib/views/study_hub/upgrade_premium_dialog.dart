import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';
import 'package:vector_academy/views/views.dart';

Future<void> showUpgradeToPremiumDialog({
  String feature = 'this feature',
}) async {
  final arguments = {'prioritizePlanner': true};
  final context = Get.context;
  if (context == null) {
    Get.toNamed(VIEWS.payments.path, arguments: arguments);
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: Text(
          'Upgrade to a Planner or full courses + planner package to use $feature. '
          'A single-course purchase does not unlock Pomodoro, Reading Plan, or Challenge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.toNamed(VIEWS.payments.path, arguments: arguments);
            },
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      );
    },
  );
}
