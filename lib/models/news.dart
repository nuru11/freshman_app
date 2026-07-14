import 'package:json_annotation/json_annotation.dart';

part 'news.g.dart';

@JsonSerializable()
class News {
  final int id;
  final String title;
  final String content;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final String category;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.coverImage,
    required this.category,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
  Map<String, dynamic> toJson() => _$NewsToJson(this);
}
