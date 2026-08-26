import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vector_academy/utils/app_clock.dart';

part 'study_plan.g.dart';

DateTime? studyPlanDateTimeFromJson(String? value) {
  if (value == null) return null;
  return DateTime.parse(value).toLocal();
}

String? studyPlanDateTimeToJson(DateTime? value) {
  return value?.toUtc().toIso8601String();
}

@JsonSerializable()
class StudyPlanAlarm {
  final String id;
  @JsonKey(name: 'offset_minutes')
  final int offsetMinutes;
  final String sound;
  final String vibration;
  @JsonKey(name: 'snooze_minutes')
  final int snoozeMinutes;
  final bool enabled;

  const StudyPlanAlarm({
    required this.id,
    this.offsetMinutes = 0,
    this.sound = 'alarm',
    this.vibration = 'default',
    this.snoozeMinutes = 5,
    this.enabled = true,
  });

  factory StudyPlanAlarm.fromJson(Map<String, dynamic> json) =>
      _$StudyPlanAlarmFromJson(json);
  Map<String, dynamic> toJson() => _$StudyPlanAlarmToJson(this);

  StudyPlanAlarm copyWith({
    String? id,
    int? offsetMinutes,
    String? sound,
    String? vibration,
    int? snoozeMinutes,
    bool? enabled,
  }) {
    return StudyPlanAlarm(
      id: id ?? this.id,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      enabled: enabled ?? this.enabled,
    );
  }

  static StudyPlanAlarm defaultAlarm() {
    return StudyPlanAlarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      offsetMinutes: 0,
      sound: 'alarm',
    );
  }
}

@JsonSerializable()
class StudyPlan {
  final int id;
  final String title;
  final String description;
  final String subject;
  @JsonKey(
    name: 'due_date',
    includeIfNull: false,
    fromJson: studyPlanDateTimeFromJson,
    toJson: studyPlanDateTimeToJson,
  )
  final DateTime? dueDate; // Kept for backward compatibility
  @JsonKey(
    name: 'start_date',
    includeIfNull: false,
    fromJson: studyPlanDateTimeFromJson,
    toJson: studyPlanDateTimeToJson,
  )
  final DateTime? startDate; // Start date and time
  @JsonKey(
    name: 'end_date',
    includeIfNull: false,
    fromJson: studyPlanDateTimeFromJson,
    toJson: studyPlanDateTimeToJson,
  )
  final DateTime? endDate; // End date and time
  @JsonKey(name: 'completed_dates')
  final List<String> completedDates; // ISO date strings (YYYY-MM-DD)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'repeat_days')
  final List<int> repeatDays; // Days of week (1=Monday, 7=Sunday)
  @JsonKey(name: 'alarms_enabled')
  final bool alarmsEnabled;
  final List<StudyPlanAlarm> alarms;

  StudyPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    this.dueDate,
    required this.startDate,
    required this.endDate,
    this.completedDates = const [],
    required this.createdAt,
    this.repeatDays = const [],
    this.alarmsEnabled = false,
    this.alarms = const [],
  });

  bool get isRepeating => repeatDays.isNotEmpty;

  List<StudyPlanAlarm> get enabledAlarms {
    if (alarms.isEmpty) return [StudyPlanAlarm.defaultAlarm()];
    return alarms.where((a) => a.enabled).toList();
  }

  DateTime? get _notificationBase => dueDate ?? startDate ?? endDate;

  /// Next fire time for [alarm], matching scheduled notification logic.
  DateTime? nextNotificationAt({
    StudyPlanAlarm? alarm,
    bool? alarmsOn,
    DateTime? now,
  }) {
    if (!(alarmsOn ?? alarmsEnabled)) return null;
    final base = _notificationBase;
    if (base == null) return null;
    final target = alarm ??
        (enabledAlarms.isEmpty ? null : enabledAlarms.first);
    if (target == null) return null;
    final from = now ?? AppClock.now();

    if (isRepeating) {
      return _nextRepeatingNotificationAt(target, from);
    }

    final scheduled = base.subtract(Duration(minutes: target.offsetMinutes));
    return AppClock.applyNotifyGrace(scheduled, from);
  }

  DateTime? soonestNotificationAt({
    bool? alarmsOn,
    List<StudyPlanAlarm>? alarmList,
    DateTime? now,
  }) {
    if (!(alarmsOn ?? alarmsEnabled)) return null;
    final list = alarmList ?? alarms;
    final enabled = list.isEmpty
        ? [StudyPlanAlarm.defaultAlarm()]
        : list.where((a) => a.enabled).toList();
    if (enabled.isEmpty) return null;
    DateTime? soonest;
    for (final alarm in enabled) {
      final next = nextNotificationAt(alarm: alarm, alarmsOn: true, now: now);
      if (next == null) continue;
      if (soonest == null || next.isBefore(soonest)) soonest = next;
    }
    return soonest;
  }

  DateTime? _nextRepeatingNotificationAt(StudyPlanAlarm alarm, DateTime from) {
    final start = startDate?.toLocal();
    if (start == null || repeatDays.isEmpty) return null;

    var minute = start.minute - alarm.offsetMinutes;
    var hour = start.hour;
    while (minute < 0) {
      minute += 60;
      hour -= 1;
    }
    while (hour < 0) {
      hour += 24;
    }

    for (var i = 0; i <= 14; i++) {
      final day = DateTime(from.year, from.month, from.day).add(Duration(days: i));
      if (!repeatDays.contains(day.weekday)) continue;
      final candidate = DateTime(day.year, day.month, day.day, hour, minute);
      final fireAt = AppClock.applyNotifyGrace(candidate, from);
      if (fireAt != null) return fireAt;
    }
    return null;
  }

  // Check if plan is completed for a specific date
  bool isCompletedForDate(DateTime? date) {
    if (date == null) return false;
    final dateStr = _dateToString(date);
    return completedDates.contains(dateStr);
  }

  // Convert DateTime to YYYY-MM-DD string
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get completion status for the original due date (for backward compatibility)
  // Uses endDate if available, otherwise falls back to dueDate
  bool get isCompleted {
    final dateToCheck = endDate ?? dueDate;
    return isCompletedForDate(dateToCheck);
  }

  // Get the effective date for filtering/sorting (uses startDate, endDate, or dueDate)
  DateTime? get effectiveDate => startDate;

  StudyPlan copyWith({
    int? id,
    String? title,
    String? description,
    String? subject,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? completedDates,
    DateTime? createdAt,
    List<int>? repeatDays,
    bool? alarmsEnabled,
    List<StudyPlanAlarm>? alarms,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      repeatDays: repeatDays ?? this.repeatDays,
      alarmsEnabled: alarmsEnabled ?? this.alarmsEnabled,
      alarms: alarms ?? this.alarms,
    );
  }

  Map<String, dynamic> toJson() => _$StudyPlanToJson(this);

  factory StudyPlan.fromJson(Map<String, dynamic> json) =>
      _$StudyPlanFromJson(json);
}

class StudyPlanTypeAdapter implements TypeAdapter<StudyPlan> {
  @override
  StudyPlan read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    // Convert to Map<String, dynamic> for fromJson
    final jsonMap = Map<String, dynamic>.from(json);
    return StudyPlan.fromJson(jsonMap);
  }

  @override
  int get typeId => 102;

  @override
  void write(BinaryWriter writer, StudyPlan obj) {
    writer.write(obj.toJson());
  }
}
