import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

@JsonSerializable()
class Chapter {
  final int id;
  @JsonKey(name: 'chapter_number')
  final int chapterNumber;
  @JsonKey(name: 'section_role', defaultValue: 'chapter')
  final String sectionRole;
  final int subject;
  final String name;
  final String? description;
  final List notes;
  final List quizzes;
  final List videos;

  Chapter({
    required this.id,
    required this.chapterNumber,
    this.sectionRole = 'chapter',
    required this.subject,
    required this.name,
    required this.description,
    this.notes = const [],
    this.quizzes = const [],
    this.videos = const [],
  });

  bool get isIntro => sectionRole == 'intro';
  bool get isOutro => sectionRole == 'outro';
  bool get isNumbered => !isIntro && !isOutro;

  /// Stored chapter number minus earlier Intro/Outro rows.
  /// Unflagged subjects keep their existing numbers.
  /// If every numbered sibling shares one stored number, use list order.
  int displayNumber(Iterable<Chapter> siblings) {
    final numbered = siblings.where((chapter) => chapter.isNumbered).toList();
    if (isNumbered && numbered.length > 1) {
      final storedNumber = numbered.first.chapterNumber;
      final collapsed = numbered.every(
        (chapter) => chapter.chapterNumber == storedNumber,
      );
      if (collapsed) {
        final index = numbered.indexWhere((chapter) => chapter.id == id);
        return index >= 0 ? index + 1 : 1;
      }
    }

    final offset = siblings
        .where(
          (chapter) =>
              !chapter.isNumbered && chapter.chapterNumber < chapterNumber,
        )
        .length;
    return chapterNumber - offset;
  }

  /// Intro, Outro, or "Chapter N" using the shifted display number.
  String progressLabel(Iterable<Chapter> siblings) {
    if (isIntro) return 'Intro';
    if (isOutro) return 'Outro';
    return 'Chapter ${displayNumber(siblings)}';
  }

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterToJson(this);

  /// Hive rows may use `chapter_number` or the older `chapterNumber` key.
  factory Chapter.fromCache(Map<dynamic, dynamic> json) {
    final role = json['sectionRole'] ?? json['section_role'] ?? 'chapter';
    return Chapter(
      id: _cachedInt(json['id'], 0),
      chapterNumber: _cachedInt(
        json['chapter_number'] ?? json['chapterNumber'],
        1,
      ),
      sectionRole: role.toString(),
      subject: _cachedInt(json['subject'], 1),
      name: json['name']?.toString() ?? '',
      description: json['description'] is String
          ? json['description'] as String
          : null,
      notes: _cachedList(json['notes']),
      quizzes: _cachedList(json['quizzes']),
      videos: _cachedList(json['videos']),
    );
  }

  static List<Chapter> listFromCache(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) {
          if (entry is Chapter) return entry;
          if (entry is Map) return Chapter.fromCache(entry);
          return null;
        })
        .whereType<Chapter>()
        .toList();
  }
}

int _cachedInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

List _cachedList(dynamic value) => value is List ? value : const [];

class ChapterTypeAdapter implements TypeAdapter<Chapter> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    return Chapter.fromCache(json);
  }

  @override
  int get typeId => 1;

  @override
  void write(BinaryWriter writer, Chapter obj) {
    writer.write(obj.toJson());
  }
}
