import 'package:json_annotation/json_annotation.dart';

part 'package.g.dart';

@JsonSerializable()
class Package {
  final int id;
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'duration_days')
  final int durationDays;
  final List<int> exams;
  final List<int> subjects;
  final int? grade;
  @JsonKey(name: 'is_locked')
  final bool isLocked;

  Package({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.exams,
    required this.subjects,
    required this.grade,
    required this.isLocked,
  });

  factory Package.fromJson(Map<String, dynamic> json) =>
      _$PackageFromJson(json);
  Map<String, dynamic> toJson() => _$PackageToJson(this);
}
