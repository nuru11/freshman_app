import 'package:json_annotation/json_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final int id;
  final String content;
  final String? image;
  final List<Choice> choices;

  @JsonKey(name: 'image_path')
  String? imagePath;

  String? explanation;

  @JsonKey(name: 'has_user_answered')
  bool hasUserAnswered;

  String? instruction;

  Question({
    required this.id,
    required this.content,
    this.image,
    required this.choices,
    this.imagePath,
    this.explanation,
    this.instruction,
    this.hasUserAnswered = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}

@JsonSerializable()
class Choice {
  final int id;
  final String content;
  @JsonKey(name: 'is_correct')
  final bool isCorrect;

  Choice({required this.id, required this.content, required this.isCorrect});

  factory Choice.fromJson(Map<String, dynamic> json) => _$ChoiceFromJson(json);
  Map<String, dynamic> toJson() => _$ChoiceToJson(this);
}

class ChoiceTypeAdapter implements TypeAdapter<Choice> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);
    return Choice.fromJson(json_);
  }

  @override
  int get typeId => 16;

  @override
  void write(BinaryWriter writer, Choice obj) {
    writer.write(obj.toJson());
  }
}

class QuestionTypeAdapter implements TypeAdapter<Question> {
  @override
  read(BinaryReader reader) {
    final json = reader.read() as Map<dynamic, dynamic>;
    final json_ = Map<String, dynamic>.from(json);

    final choices = json_['choices'].cast<Choice>();
    return Question(
      id: json_['id'],
      content: json_['content'],
      explanation: json_['explanation'],
      choices: choices,
      image: json_['image'],
    );
  }

  @override
  int get typeId => 6;

  @override
  void write(BinaryWriter writer, Question obj) {
    writer.write(obj.toJson());
  }
}
