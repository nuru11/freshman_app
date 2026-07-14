// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String,
  chapter: (json['chapter'] as num?)?.toInt(),
  size: (json['size'] as num?)?.toInt() ?? 0,
  filePath: json['file_path'] as String?,
  isDownloaded: json['is_downloaded'] as bool? ?? false,
  isLocked: json['is_locked'] as bool? ?? true,
);

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'chapter': instance.chapter,
  'is_downloaded': instance.isDownloaded,
  'file_path': instance.filePath,
  'size': instance.size,
  'is_locked': instance.isLocked,
};
