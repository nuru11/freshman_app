// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
  appName: json['app_name'] as String,
  bannerColor: json['banner_color'] as String,
  appLogo: json['app_logo'] as String,
);

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
  'app_name': instance.appName,
  'app_logo': instance.appLogo,
  'banner_color': instance.bannerColor,
};
