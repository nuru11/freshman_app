import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'app_header_text.g.dart';

@JsonSerializable()
class AppHeaderText {
  final String text;

  @JsonKey(name: 'gradient_start_color')
  final String? gradientStart;
  @JsonKey(name: 'gradient_end_color')
  final String? gradientEnd;
  @JsonKey(name: 'telegram_channel_url')
  final String? link;
  @JsonKey(name: 'tag_line_text')
  final String? tagLineText;
  @JsonKey(name: 'show_tag_line_text')
  final bool? showTagLineText;
  @JsonKey(name: 'text_color')
  final String? textColor;
  @JsonKey(name: 'tag_line_text_color')
  final String? tagLineTextColor;
  AppHeaderText({
    required this.text,
    this.gradientStart,
    this.gradientEnd,
    this.link,
    this.tagLineText,
    this.showTagLineText,
    this.textColor,
    this.tagLineTextColor,
  });

  factory AppHeaderText.fromJson(Map<String, dynamic> json) =>
      _$AppHeaderTextFromJson(json);
  Map<String, dynamic> toJson() => _$AppHeaderTextToJson(this);

  @override
  String toString() {
    return 'AppHeaderText(text: $text, gradientStart: $gradientStart, gradientEnd: $gradientEnd)';
  }
}

class AppHeaderTextTypeAdapter implements TypeAdapter<AppHeaderText> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    return AppHeaderText.fromJson(json_);
  }

  @override
  int get typeId => 20;

  @override
  void write(BinaryWriter writer, AppHeaderText obj) {
    writer.write(obj.toJson());
  }
}
