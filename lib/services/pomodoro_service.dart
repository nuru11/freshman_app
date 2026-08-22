import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:vector_academy/services/notification_service.dart';
import 'package:vector_academy/utils/storages/config.dart';
import 'package:vector_academy/utils/study_planner_reminder_permissions.dart';

enum PomodoroPhase { work, gap }

class PomodoroService extends GetxService {
  static const workDuration = Duration(minutes: 25);
  static const gapDuration = Duration(minutes: 40);

  DateTime? startedAt;
  PomodoroPhase phase = PomodoroPhase.work;
  bool isRunning = false;
  Duration accumulated = Duration.zero;

  Duration get interval =>
      phase == PomodoroPhase.work ? workDuration : gapDuration;

  Duration remaining() {
    if (!isRunning || startedAt == null) {
      final left = interval - accumulated;
      return left.isNegative ? Duration.zero : left;
    }
    final elapsed = DateTime.now().difference(startedAt!) + accumulated;
    final left = interval - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isFinished => remaining() == Duration.zero && startedAt != null;

  @override
  void onInit() {
    super.onInit();
    _load();
    _catchUpIfNeeded();
  }

  void _load() {
    final raw = ConfigPreference.getPomodoroState();
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      isRunning = json['is_running'] as bool? ?? false;
      phase = (json['phase'] as String?) == 'gap'
          ? PomodoroPhase.gap
          : PomodoroPhase.work;
      final started = json['started_at'] as String?;
      startedAt = started == null ? null : DateTime.tryParse(started);
      accumulated = Duration(seconds: json['accumulated_seconds'] as int? ?? 0);
    } catch (_) {}
  }

  Future<void> _persist() async {
    await ConfigPreference.setPomodoroState(
      jsonEncode({
        'is_running': isRunning,
        'phase': phase == PomodoroPhase.gap ? 'gap' : 'work',
        'started_at': startedAt?.toIso8601String(),
        'accumulated_seconds': accumulated.inSeconds,
      }),
    );
  }

  void _catchUpIfNeeded() {
    if (!isRunning || startedAt == null) return;
    if (remaining() == Duration.zero) {
      _advancePhase();
    }
  }

  void _advancePhase() {
    phase = phase == PomodoroPhase.work
        ? PomodoroPhase.gap
        : PomodoroPhase.work;
    startedAt = DateTime.now();
    accumulated = Duration.zero;
    isRunning = true;
  }

  Future<void> start() async {
    await StudyPlannerReminderPermissions.ensureBeforeScheduling();
    if (isRunning) return;
    startedAt = DateTime.now();
    isRunning = true;
    await _persist();
    await _scheduleEnd();
  }

  Future<void> pause() async {
    if (!isRunning || startedAt == null) return;
    accumulated += DateTime.now().difference(startedAt!);
    isRunning = false;
    startedAt = null;
    await _persist();
    await Get.find<LocalNotificationService>().cancelPomodoroNotifications();
  }

  Future<void> skip() async {
    _advancePhase();
    await _persist();
    if (isRunning) await _scheduleEnd();
  }

  Future<void> reset() async {
    isRunning = false;
    startedAt = null;
    accumulated = Duration.zero;
    phase = PomodoroPhase.work;
    await _persist();
    await Get.find<LocalNotificationService>().cancelPomodoroNotifications();
  }

  Future<void> tickCatchUp() async {
    if (isFinished) {
      _advancePhase();
      await _persist();
      await _scheduleEnd();
    }
  }

  Future<void> _scheduleEnd() async {
    final endAt = DateTime.now().add(remaining());
    await Get.find<LocalNotificationService>().schedulePomodoroEnd(
      at: endAt,
      isWorkPhase: phase == PomodoroPhase.work,
    );
  }
}
