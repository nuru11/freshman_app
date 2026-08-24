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
        final isWork = controller.isWork;
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
                    controller.phaseDurationLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CycleDots(
                    completedWorkSessions: controller.completedWorkSessions,
                    isWork: isWork,
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
            FreshmanSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durations',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.isRunning
                        ? 'Pause the timer to change times.'
                        : 'Customize focus and break lengths.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DurationStepper(
                    label: 'Focus',
                    minutes: controller.service.workMinutes,
                    enabled: !controller.isRunning,
                    onMinus: () => controller.adjustWorkMinutes(-1),
                    onPlus: () => controller.adjustWorkMinutes(1),
                  ),
                  _DurationStepper(
                    label: 'Short break',
                    minutes: controller.service.shortBreakMinutes,
                    enabled: !controller.isRunning,
                    onMinus: () => controller.adjustShortBreakMinutes(-1),
                    onPlus: () => controller.adjustShortBreakMinutes(1),
                  ),
                  _DurationStepper(
                    label: 'Long break',
                    minutes: controller.service.longBreakMinutes,
                    enabled: !controller.isRunning,
                    onMinus: () => controller.adjustLongBreakMinutes(-1),
                    onPlus: () => controller.adjustLongBreakMinutes(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Four focus sessions, with a short break after each of the first three '
              'and a long break after the fourth. Alarms still ring if you lock '
              'the phone or close the app.',
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

class _CycleDots extends StatelessWidget {
  const _CycleDots({
    required this.completedWorkSessions,
    required this.isWork,
  });

  final int completedWorkSessions;
  final bool isWork;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(PomodoroService.worksPerCycle, (index) {
        final filled = index < completedWorkSessions;
        final current = isWork && index == completedWorkSessions;
        final color = current
            ? primaryColor
            : filled
                ? primaryColor.withValues(alpha: 0.45)
                : onSurfaceVariant.withValues(alpha: 0.25);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: current ? 12 : 10,
            height: current ? 12 : 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: current
                  ? Border.all(color: primaryColor, width: 2)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _DurationStepper extends StatelessWidget {
  const _DurationStepper({
    required this.label,
    required this.minutes,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int minutes;
  final bool enabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: enabled && minutes > PomodoroService.minMinutes
                ? onMinus
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$minutes min',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled && minutes < PomodoroService.maxMinutes
                ? onPlus
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
