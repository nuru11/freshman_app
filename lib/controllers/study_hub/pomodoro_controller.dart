import 'dart:async';

import 'package:get/get.dart';
import 'package:vector_academy/services/pomodoro_service.dart';

class PomodoroController extends GetxController {
  final PomodoroService service = Get.find<PomodoroService>();

  Timer? _timer;

  String get phaseLabel {
    switch (service.phase) {
      case PomodoroPhase.work:
        return 'Focus ${service.focusNumber} of ${PomodoroService.worksPerCycle}';
      case PomodoroPhase.shortBreak:
        return 'Short break';
      case PomodoroPhase.longBreak:
        return 'Long break';
    }
  }

  String get phaseDurationLabel {
    final minutes = service.interval.inMinutes;
    switch (service.phase) {
      case PomodoroPhase.work:
        return '$minutes-minute focus';
      case PomodoroPhase.shortBreak:
        return '$minutes-minute short break';
      case PomodoroPhase.longBreak:
        return '$minutes-minute long break';
    }
  }

  bool get isWork => service.phase == PomodoroPhase.work;

  Duration get remaining => service.remaining();

  String get remainingLabel {
    final d = remaining;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  bool get isRunning => service.isRunning;

  int get completedWorkSessions => service.completedWorkSessions;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await service.tickCatchUp();
      update();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> start() async {
    await service.start();
    update();
  }

  Future<void> pause() async {
    await service.pause();
    update();
  }

  Future<void> skip() async {
    await service.skip();
    update();
  }

  Future<void> reset() async {
    await service.reset();
    update();
  }

  Future<void> adjustWorkMinutes(int delta) async {
    await service.setWorkMinutes(service.workMinutes + delta);
    update();
  }

  Future<void> adjustShortBreakMinutes(int delta) async {
    await service.setShortBreakMinutes(service.shortBreakMinutes + delta);
    update();
  }

  Future<void> adjustLongBreakMinutes(int delta) async {
    await service.setLongBreakMinutes(service.longBreakMinutes + delta);
    update();
  }
}
