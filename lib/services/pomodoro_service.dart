import 'dart:convert';

import 'package:get/get.dart';
import 'package:vector_academy/services/notification_service.dart';
import 'package:vector_academy/utils/storages/config.dart';
import 'package:vector_academy/utils/study_planner_reminder_permissions.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroAlarm {
  const PomodoroAlarm({
    required this.at,
    required this.endingPhase,
    required this.nextPhase,
    required this.nextDuration,
  });

  final DateTime at;
  final PomodoroPhase endingPhase;
  final PomodoroPhase nextPhase;
  final Duration nextDuration;

  String get title {
    switch (endingPhase) {
      case PomodoroPhase.work:
        return 'Focus session complete';
      case PomodoroPhase.shortBreak:
        return 'Short break complete';
      case PomodoroPhase.longBreak:
        return 'Long break complete';
    }
  }

  String get body {
    switch (nextPhase) {
      case PomodoroPhase.shortBreak:
        return 'Time for a ${nextDuration.inMinutes}-minute short break.';
      case PomodoroPhase.longBreak:
        return 'Time for a ${nextDuration.inMinutes}-minute long break.';
      case PomodoroPhase.work:
        return endingPhase == PomodoroPhase.longBreak
            ? 'New cycle — start focusing.'
            : 'Back to ${nextDuration.inMinutes} minutes of focus.';
    }
  }

  String get phaseName {
    switch (endingPhase) {
      case PomodoroPhase.work:
        return 'work';
      case PomodoroPhase.shortBreak:
        return 'shortBreak';
      case PomodoroPhase.longBreak:
        return 'longBreak';
    }
  }
}

class PomodoroService extends GetxService {
  static const int minMinutes = 1;
  static const int maxMinutes = 90;
  static const int defaultWorkMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;
  static const int worksPerCycle = 4;
  static const int scheduledAlarmCount = 16;

  int workMinutes = defaultWorkMinutes;
  int shortBreakMinutes = defaultShortBreakMinutes;
  int longBreakMinutes = defaultLongBreakMinutes;

  DateTime? startedAt;
  PomodoroPhase phase = PomodoroPhase.work;
  int completedWorkSessions = 0;
  bool isRunning = false;
  Duration accumulated = Duration.zero;

  Duration get interval {
    switch (phase) {
      case PomodoroPhase.work:
        return Duration(minutes: workMinutes);
      case PomodoroPhase.shortBreak:
        return Duration(minutes: shortBreakMinutes);
      case PomodoroPhase.longBreak:
        return Duration(minutes: longBreakMinutes);
    }
  }

  int get focusNumber => completedWorkSessions + 1;

  Duration remaining() {
    final left = interval - _elapsed();
    return left.isNegative ? Duration.zero : left;
  }

  Duration _elapsed() {
    if (!isRunning || startedAt == null) return accumulated;
    return DateTime.now().difference(startedAt!) + accumulated;
  }

  static int clampMinutes(int minutes) {
    if (minutes < minMinutes) return minMinutes;
    if (minutes > maxMinutes) return maxMinutes;
    return minutes;
  }

  Duration durationFor(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return Duration(minutes: workMinutes);
      case PomodoroPhase.shortBreak:
        return Duration(minutes: shortBreakMinutes);
      case PomodoroPhase.longBreak:
        return Duration(minutes: longBreakMinutes);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _load();
    _catchUpIfNeeded();
    if (isRunning) {
      _persist();
      _scheduleUpcoming();
    }
  }

  void _load() {
    final raw = ConfigPreference.getPomodoroState();
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      isRunning = json['is_running'] as bool? ?? false;
      phase = _phaseFromName(json['phase'] as String?);
      final started = json['started_at'] as String?;
      startedAt = started == null ? null : DateTime.tryParse(started);
      accumulated = Duration(seconds: json['accumulated_seconds'] as int? ?? 0);
      completedWorkSessions =
          (json['completed_work_sessions'] as int? ?? 0).clamp(0, worksPerCycle);
      workMinutes = clampMinutes(
        json['work_minutes'] as int? ?? defaultWorkMinutes,
      );
      shortBreakMinutes = clampMinutes(
        json['short_break_minutes'] as int? ?? defaultShortBreakMinutes,
      );
      longBreakMinutes = clampMinutes(
        json['long_break_minutes'] as int? ?? defaultLongBreakMinutes,
      );
    } catch (_) {}
  }

  PomodoroPhase _phaseFromName(String? name) {
    switch (name) {
      case 'shortBreak':
      case 'gap':
        return PomodoroPhase.shortBreak;
      case 'longBreak':
        return PomodoroPhase.longBreak;
      default:
        return PomodoroPhase.work;
    }
  }

  String _phaseName(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return 'work';
      case PomodoroPhase.shortBreak:
        return 'shortBreak';
      case PomodoroPhase.longBreak:
        return 'longBreak';
    }
  }

  Future<void> _persist() async {
    await ConfigPreference.setPomodoroState(
      jsonEncode({
        'is_running': isRunning,
        'phase': _phaseName(phase),
        'started_at': startedAt?.toIso8601String(),
        'accumulated_seconds': accumulated.inSeconds,
        'completed_work_sessions': completedWorkSessions,
        'work_minutes': workMinutes,
        'short_break_minutes': shortBreakMinutes,
        'long_break_minutes': longBreakMinutes,
      }),
    );
  }

  void _catchUpIfNeeded() {
    if (!isRunning) return;
    var safety = 0;
    while (_elapsed() >= interval && safety < 64) {
      _advancePhase(overtime: _elapsed() - interval);
      safety++;
    }
  }

  void _advancePhase({Duration overtime = Duration.zero}) {
    if (phase == PomodoroPhase.work) {
      completedWorkSessions += 1;
      if (completedWorkSessions >= worksPerCycle) {
        phase = PomodoroPhase.longBreak;
      } else {
        phase = PomodoroPhase.shortBreak;
      }
    } else {
      if (phase == PomodoroPhase.longBreak) {
        completedWorkSessions = 0;
      }
      phase = PomodoroPhase.work;
    }
    startedAt = DateTime.now();
    accumulated = overtime.isNegative ? Duration.zero : overtime;
    isRunning = true;
  }

  ({PomodoroPhase phase, int completedWorkSessions}) _nextState(
    PomodoroPhase current,
    int completed,
  ) {
    if (current == PomodoroPhase.work) {
      final nextCompleted = completed + 1;
      if (nextCompleted >= worksPerCycle) {
        return (
          phase: PomodoroPhase.longBreak,
          completedWorkSessions: worksPerCycle,
        );
      }
      return (
        phase: PomodoroPhase.shortBreak,
        completedWorkSessions: nextCompleted,
      );
    }
    if (current == PomodoroPhase.longBreak) {
      return (phase: PomodoroPhase.work, completedWorkSessions: 0);
    }
    return (phase: PomodoroPhase.work, completedWorkSessions: completed);
  }

  List<PomodoroAlarm> upcomingAlarms({int count = scheduledAlarmCount}) {
    var fireAt = DateTime.now().add(remaining());
    var simPhase = phase;
    var simCompleted = completedWorkSessions;
    final alarms = <PomodoroAlarm>[];
    for (var i = 0; i < count; i++) {
      final next = _nextState(simPhase, simCompleted);
      alarms.add(
        PomodoroAlarm(
          at: fireAt,
          endingPhase: simPhase,
          nextPhase: next.phase,
          nextDuration: durationFor(next.phase),
        ),
      );
      simPhase = next.phase;
      simCompleted = next.completedWorkSessions;
      fireAt = fireAt.add(durationFor(simPhase));
    }
    return alarms;
  }

  Future<void> setWorkMinutes(int minutes) async {
    if (isRunning) return;
    workMinutes = clampMinutes(minutes);
    await _persist();
  }

  Future<void> setShortBreakMinutes(int minutes) async {
    if (isRunning) return;
    shortBreakMinutes = clampMinutes(minutes);
    await _persist();
  }

  Future<void> setLongBreakMinutes(int minutes) async {
    if (isRunning) return;
    longBreakMinutes = clampMinutes(minutes);
    await _persist();
  }

  Future<void> start() async {
    await StudyPlannerReminderPermissions.ensureBeforeScheduling();
    if (isRunning) return;
    startedAt = DateTime.now();
    isRunning = true;
    _catchUpIfNeeded();
    await _persist();
    await _scheduleUpcoming();
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
    if (isRunning) await _scheduleUpcoming();
  }

  Future<void> reset() async {
    isRunning = false;
    startedAt = null;
    accumulated = Duration.zero;
    phase = PomodoroPhase.work;
    completedWorkSessions = 0;
    await _persist();
    await Get.find<LocalNotificationService>().cancelPomodoroNotifications();
  }

  Future<void> tickCatchUp() async {
    if (!isRunning) return;
    final previousPhase = phase;
    final previousCompleted = completedWorkSessions;
    _catchUpIfNeeded();
    if (phase != previousPhase || completedWorkSessions != previousCompleted) {
      await _persist();
    }
  }

  Future<void> _scheduleUpcoming() async {
    final alarms = upcomingAlarms();
    await Get.find<LocalNotificationService>().schedulePomodoroCycle(
      alarms
          .map(
            (alarm) => PomodoroNotificationSlot(
              at: alarm.at,
              title: alarm.title,
              body: alarm.body,
              phase: alarm.phaseName,
            ),
          )
          .toList(),
    );
  }
}
