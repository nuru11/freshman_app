import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'study_plan.g.dart';

@JsonSerializable()
class StudyPlan {
  final int id;
  final String title;
  final String description;
  final String subject;
  @JsonKey(name: 'due_date', includeIfNull: false)
  final DateTime? dueDate; // Kept for backward compatibility
  @JsonKey(name: 'start_date', includeIfNull: false)
  final DateTime? startDate; // Start date and time
  @JsonKey(name: 'end_date', includeIfNull: false)
  final DateTime? endDate; // End date and time
  @JsonKey(name: 'completed_dates')
  final List<String> completedDates; // ISO date strings (YYYY-MM-DD)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'repeat_days')
  final List<int> repeatDays; // Days of week (1=Monday, 7=Sunday)

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
  });

  bool get isRepeating => repeatDays.isNotEmpty;

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
