import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'video.g.dart';

@JsonSerializable()
class Video {
  final int id;
  final int chapter;
  final int subject;
  final String title;

  final String? file;
  @JsonKey(name: 'duration_in_minutes')
  final int duration;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'is_locked')
  final bool isLocked;
  final String? description;
  @JsonKey(name: 'is_watched')
  final bool isWatched;
  @JsonKey(name: 'is_downloaded')
  bool isDownloaded;

  final String? thumbnail;
  @JsonKey(name: 'file_path')
  String? filePath;

  // Add download progress tracking properties
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isDownloading;

  @JsonKey(includeFromJson: false, includeToJson: false)
  double downloadProgress;

  Video({
    required this.id,
    required this.chapter,
    required this.subject,
    required this.title,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.file,
    this.isLocked = true,
    this.isWatched = false,
    this.description,
    this.thumbnail,
    this.isDownloaded = false,
    this.filePath,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);
}

class VideoTypeAdapter implements TypeAdapter<Video> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    return Video.fromJson(json_);
  }

  @override
  int get typeId => 9;

  @override
  void write(BinaryWriter writer, Video obj) {
    writer.write(obj.toJson());
  }
}
