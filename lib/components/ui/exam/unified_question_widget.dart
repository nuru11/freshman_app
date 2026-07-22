import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:vector_academy/models/models.dart';

class UnifiedQuestionWidget extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;
  final int? selectedChoiceId;
  final int? correctChoiceId;
  final bool showAnswers;
  final Function(Choice)? onChoiceSelected;
  final bool isInteractive;
  final VoidCallback? onImageTap;

  const UnifiedQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    this.selectedChoiceId,
    this.correctChoiceId,
    this.showAnswers = false,
    this.onChoiceSelected,
    this.isInteractive = true,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TeXView(
        child: TeXViewDocument(_buildCompleteHTML()),
        style: TeXViewStyle(
          contentColor: theme.colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          textAlign: TeXViewTextAlign.left,
          padding: TeXViewPadding.all(8),
          margin: TeXViewMargin.all(0),
        ),
      ),
    );
  }

  String _buildCompleteHTML() {
    StringBuffer html = StringBuffer();

    // Add question header
    html.write('''
      <div style="
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
        padding: 12px 16px;
        background-color: #f5f5f5;
        border-radius: 20px;
        border: 1px solid #e0e0e0;
      ">
        <div style="
          padding: 6px 12px;
          background-color: #e3f2fd;
          border-radius: 20px;
          color: #1976d2;
          font-weight: 600;
          font-size: 14px;
        ">
          Question $questionNumber of $totalQuestions
        </div>
    ''');

    // Add image button if question has image
    if (question.image != null) {
      html.write('''
        <button id="image_button" style="
          background-color: #f3e5f5;
          border: none;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          color: #7b1fa2;
        ">
          📷
        </button>
      ''');
    }

    html.write('</div>');

    // Add question content
    html.write('<div style="margin-bottom: 24px;">');
    html.write(_processText(question.content));
    html.write('</div>');

    // Add image if exists
    if (question.image != null) {
      html.write('''
        <div style="
          margin: 16px 0;
          text-align: center;
          border: 1px solid #e0e0e0;
          border-radius: 12px;
          overflow: hidden;
        ">
          <img src="${question.image}" 
               style="max-width: 100%; max-height: 300px; object-fit: contain;"
               onclick="showImage()"
               alt="Question Image" />
        </div>
      ''');
    }

    // Add choices section
    html.write('''
      <div style="
        margin-top: 24px;
        margin-bottom: 16px;
        font-size: 16px;
        font-weight: 600;
        color: #333;
      ">
        Select your answer:
      </div>
    ''');

    // Add choices
    html.write('<div style="margin-top: 16px;">');
    for (int i = 0; i < question.choices.length; i++) {
      final choice = question.choices[i];
      final choiceLabel = String.fromCharCode(65 + i); // A, B, C, D...
      final isSelected = choice.id == selectedChoiceId;
      final isCorrect = showAnswers && choice.id == correctChoiceId;
      final isIncorrect =
          showAnswers &&
          choice.id == selectedChoiceId &&
          choice.id != correctChoiceId;

      String borderColor = '#e0e0e0';
      String backgroundColor = 'transparent';
      String textColor = '#333';
      String iconColor = '#666';
      String icon = '○';

      if (isCorrect) {
        borderColor = '#4caf50';
        backgroundColor = '#e8f5e8';
        textColor = '#2e7d32';
        iconColor = '#4caf50';
        icon = '✓';
      } else if (isIncorrect) {
        borderColor = '#f44336';
        backgroundColor = '#ffebee';
        textColor = '#c62828';
        iconColor = '#f44336';
        icon = '✗';
      } else if (isSelected) {
        borderColor = '#1976d2';
        backgroundColor = '#e3f2fd';
        textColor = '#1565c0';
        iconColor = '#1976d2';
        icon = '✓';
      }

      String choiceStyle =
          '''
        display: flex;
        align-items: center;
        padding: 16px;
        margin-bottom: 12px;
        border: 2px solid $borderColor;
        border-radius: 16px;
        background-color: $backgroundColor;
        cursor: ${isInteractive ? 'pointer' : 'default'};
        transition: all 0.2s ease;
        color: $textColor;
      ''';

      html.write('''
        <div id="choice_${choice.id}" style="$choiceStyle">
          <div style="
            width: 32px;
            height: 32px;
            border-radius: 16px;
            background-color: $borderColor;
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            margin-right: 16px;
            font-size: 14px;
          ">$choiceLabel</div>
          <div style="flex: 1;">${_processText(choice.content)}</div>
          <div style="
            margin-left: 12px;
            color: $iconColor;
            font-size: 18px;
            font-weight: bold;
          ">$icon</div>
        </div>
      ''');
    }
    html.write('</div>');

    return html.toString();
  }

  String _processText(String text) {
    // Convert LaTeX expressions to proper TeX format
    String processedText = text;

    // Handle display math ($$...$$)
    processedText = processedText.replaceAllMapped(
      RegExp(r'\$\$([^$]+)\$\$'),
      (match) =>
          '<div style="text-align: center; font-size: 18px; margin: 8px 0;">\\(${match.group(1)}\\)</div>',
    );

    // Handle inline math ($...$)
    processedText = processedText.replaceAllMapped(
      RegExp(r'\$([^$]+)\$'),
      (match) => '\\(${match.group(1)}\\)',
    );

    // Handle bold text (**text**)
    processedText = processedText.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );

    // Handle italic text (*text*)
    processedText = processedText.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => '<em>${match.group(1)}</em>',
    );

    // Handle code text (`text`)
    processedText = processedText.replaceAllMapped(
      RegExp(r'`(.*?)`'),
      (match) =>
          '<code style="background-color: #f5f5f5; padding: 2px 4px; border-radius: 3px; font-family: monospace;">${match.group(1)}</code>',
    );

    return processedText;
  }
}
