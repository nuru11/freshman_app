import 'package:json_annotation/json_annotation.dart';
import 'package:vector_academy/models/models.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'exam.g.dart';

class ExamGrouping {
  final int id;
  final String name;
  final int sortOrder;
  final String? thumbnail;
  final bool isLocked;

  const ExamGrouping({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.thumbnail,
    this.isLocked = false,
  });

  factory ExamGrouping.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final thumbnail = json['thumbnail']?.toString().trim();
    return ExamGrouping(
      id: id is int ? id : int.parse(id.toString()),
      name: json['name']?.toString() ?? '',
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse('${json['sort_order']}') ?? 0,
      thumbnail: thumbnail == null || thumbnail.isEmpty ? null : thumbnail,
      isLocked: json['is_locked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sort_order': sortOrder,
    'thumbnail': thumbnail,
    'is_locked': isLocked,
  };
}

ExamGrouping? examGroupingFromDynamic(Object? value) {
  if (value == null) return null;
  if (value is ExamGrouping) return value;
  if (value is Map) {
    return ExamGrouping.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

class ExamCategoryBrowse {
  final int id;
  final String name;
  final int sortOrder;
  final String? thumbnail;
  final List<ExamGrouping> sections;

  const ExamCategoryBrowse({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.thumbnail,
    this.sections = const [],
  });

  factory ExamCategoryBrowse.fromJson(Map<String, dynamic> json) {
    final grouping = ExamGrouping.fromJson(json);
    final rawSections = json['sections'];
    final sections = rawSections is List
        ? rawSections
              .map(examGroupingFromDynamic)
              .whereType<ExamGrouping>()
              .toList()
        : <ExamGrouping>[];
    return ExamCategoryBrowse(
      id: grouping.id,
      name: grouping.name,
      sortOrder: grouping.sortOrder,
      thumbnail: grouping.thumbnail,
      sections: sections,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sort_order': sortOrder,
    'thumbnail': thumbnail,
    'sections': sections.map((section) => section.toJson()).toList(),
  };
}

@JsonSerializable()
class Exam {
  final int id;
  final String name;
  @JsonKey(name: 'exam_type')
  final String examType;
  final String? year;
  @JsonKey(name: 'total_questions')
  final int? totalQuestions;
  @JsonKey(name: 'given_time_in_minutes')
  final int duration;
  @JsonKey(name: 'is_locked')
  final bool isLocked;
  final Subject? subject;
  final String? image;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'mode_type')
  final String modeType;
  @JsonKey(name: 'exam_category')
  final ExamGrouping? examCategory;
  final ExamGrouping? section;
  @JsonKey(name: 'is_downloaded')
  bool isDownloaded;

  // New persisted state fields
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isCompleted = false;

  @JsonKey(includeFromJson: false, includeToJson: false)
  ExamProgress? progress;

  List<Question> questions;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isLoadingQuestion = false;

  Exam({
    required this.id,
    required this.name,
    required this.examType,
    this.year,
    this.totalQuestions,
    required this.duration,
    required this.isLocked,
    this.subject,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.isDownloaded = false,
    this.questions = const [],
    this.modeType = 'both',
    this.examCategory,
    this.section,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);
  Map<String, dynamic> toJson() => _$ExamToJson(this);

  // Helper getter for display
  String get title => name;
}

class ExamProgress {
  final int currentQuestionIndex;
  final List<int?> userAnswers;
  final int timeRemaining;
  final String mode;

  ExamProgress({
    required this.currentQuestionIndex,
    required this.userAnswers,
    required this.timeRemaining,
    required this.mode,
  });

  factory ExamProgress.fromMap(Map<dynamic, dynamic> map) {
    final m = Map<String, dynamic>.from(map);
    final answersDynamic = (m['selected_answers'] as List?) ?? const [];
    final answers = answersDynamic
        .map(
          (e) => e is int ? e : (e == null ? null : int.tryParse(e.toString())),
        )
        .toList();
    return ExamProgress(
      currentQuestionIndex: m['current_question_index'] ?? 0,
      userAnswers: answers.cast<int?>(),
      timeRemaining: m['remaining_time'] ?? 0,
      mode: m['mode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_question_index': currentQuestionIndex,
      'selected_answers': userAnswers,
      'remaining_time': timeRemaining,
      'mode': mode,
    };
  }
}

class ExamTypeAdapter implements TypeAdapter<Exam> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    final exam = Exam(
      id: json_['id'],
      name: json_['name'],
      examType: json_['exam_type'],
      duration: json_['given_time_in_minutes'],
      isLocked: json_['is_locked'],
      createdAt: DateTime.parse(json_['created_at']),
      updatedAt: DateTime.parse(json_['updated_at']),
      isDownloaded: json_['is_downloaded'] ?? false,
      subject: json_['subject'],
      image: json_['image'],
      totalQuestions: json_['total_questions'],
      year: json_['year'],
      modeType: json_['mode_type'] ?? 'both',
      examCategory: examGroupingFromDynamic(json_['exam_category']),
      section: examGroupingFromDynamic(json_['section']),
    );
    // hydrate extra fields if present
    exam.isCompleted = json_['is_completed'] ?? false;
    final progressMap = json_['progress'];
    if (progressMap is Map) {
      exam.progress = ExamProgress.fromMap(progressMap);
    }
    return exam;
  }

  @override
  int get typeId => 2;
  @override
  void write(BinaryWriter writer, Exam obj) {
    final json = obj.toJson();
    // persist extra fields
    json['is_completed'] = obj.isCompleted;
    if (obj.progress != null) {
      json['progress'] = obj.progress!.toMap();
    }
    writer.write(json);
  }
}
