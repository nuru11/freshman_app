// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_header_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppHeaderText _$AppHeaderTextFromJson(Map<String, dynamic> json) =>
    AppHeaderText(
      text: json['text'] as String,
      gradientStart: json['gradient_start_color'] as String?,
      gradientEnd: json['gradient_end_color'] as String?,
      link: json['telegram_channel_url'] as String?,
      tagLineText: json['tag_line_text'] as String?,
      showTagLineText: json['show_tag_line_text'] as bool?,
      textColor: json['text_color'] as String?,
      tagLineTextColor: json['tag_line_text_color'] as String?,
    );

Map<String, dynamic> _$AppHeaderTextToJson(AppHeaderText instance) =>
    <String, dynamic>{
      'text': instance.text,
      'gradient_start_color': instance.gradientStart,
      'gradient_end_color': instance.gradientEnd,
      'telegram_channel_url': instance.link,
      'tag_line_text': instance.tagLineText,
      'show_tag_line_text': instance.showTagLineText,
      'text_color': instance.textColor,
      'tag_line_text_color': instance.tagLineTextColor,
    };
