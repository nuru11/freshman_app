import 'dart:async';

import 'package:get/get.dart';
import 'package:vector_academy/services/pomodoro_service.dart';

class PomodoroController extends GetxController {
  final PomodoroService service = Get.find<PomodoroService>();
  Timer? _timer;

  String get phaseLabel =>
      service.phase == PomodoroPhase.work ? 'Work' : 'Gap';

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
}
