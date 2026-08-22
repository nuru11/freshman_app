import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/controllers/study_hub/pomodoro_controller.dart';
import 'package:vector_academy/services/pomodoro_service.dart';

class PomodoroTab extends StatelessWidget {
  const PomodoroTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PomodoroController>(
      builder: (controller) {
        final isWork = controller.service.phase == PomodoroPhase.work;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            FreshmanSurfaceCard(
              child: Column(
                children: [
                  Text(
                    controller.phaseLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isWork ? primaryColor : secondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isWork ? '25-minute focus' : '40-minute gap',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    controller.remainingLabel,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: controller.isRunning
                            ? controller.pause
                            : controller.start,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        child: Text(controller.isRunning ? 'Pause' : 'Start'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: controller.skip,
                        child: const Text('Skip'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: controller.reset,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The timer keeps running if you leave the app or lock the phone. '
              'You will get a sound and notification when it is time to switch.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
