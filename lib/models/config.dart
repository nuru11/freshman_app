import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable()
class Config {
  @JsonKey(name: 'app_name')
  final String appName;
  @JsonKey(name: 'app_logo')
  final String appLogo;
  @JsonKey(name: 'banner_color')
  final String bannerColor;

  Config({
    required this.appName,
    required this.bannerColor,
    required this.appLogo,
  });

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}
