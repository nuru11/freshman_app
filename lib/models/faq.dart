import 'package:json_annotation/json_annotation.dart';

part 'faq.g.dart';

@JsonSerializable()
class FAQ {
  final int id;
  final String question;
  final String answer;

  FAQ({required this.id, required this.question, required this.answer});

  factory FAQ.fromJson(Map<String, dynamic> json) => _$FAQFromJson(json);
  Map<String, dynamic> toJson() => _$FAQToJson(this);
}
