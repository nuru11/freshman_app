import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:vector_academy/models/models.dart';

enum ChoiceState { unselected, selected, correct, incorrect, disabled }

class ChoiceCard extends StatelessWidget {
  final Choice choice;
  final String choiceLabel;
  final ChoiceState state;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool isInteractive;

  const ChoiceCard({
    super.key,
    required this.choice,
    required this.choiceLabel,
    required this.state,
    this.onTap,
    this.showLabel = true,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = state == ChoiceState.selected;
    final isCorrect = state == ChoiceState.correct;
    final isIncorrect = state == ChoiceState.incorrect;
    final isDisabled = state == ChoiceState.disabled || !isInteractive;

    Color borderColor;
    Color backgroundColor;
    Color textColor;

    if (isCorrect) {
      borderColor = theme.colorScheme.secondary;
      backgroundColor = theme.colorScheme.secondary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.secondary;
    } else if (isIncorrect) {
      borderColor = theme.colorScheme.error;
      backgroundColor = theme.colorScheme.error.withValues(alpha: 0.1);
      textColor = theme.colorScheme.error;
    } else if (isSelected) {
      borderColor = theme.colorScheme.primary;
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.primary;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
      backgroundColor = Colors.transparent;
      textColor = theme.colorScheme.onSurface;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected || isCorrect || isIncorrect ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Choice Label
                if (showLabel) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected || isCorrect || isIncorrect
                          ? borderColor
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        choiceLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected || isCorrect || isIncorrect
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                ],

                // Choice Content
                Expanded(child: _buildChoiceContent(context, textColor)),

                // State Indicator
                if (isCorrect || isIncorrect) ...[
                  SizedBox(width: 12),
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: borderColor,
                    size: 24,
                  ),
                ] else if (isSelected) ...[
                  SizedBox(width: 12),
                  Icon(
                    Icons.radio_button_checked,
                    color: borderColor,
                    size: 24,
                  ),
                ] else if (isInteractive) ...[
                  SizedBox(width: 12),
                  Icon(
                    Icons.radio_button_unchecked,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceContent(BuildContext context, Color textColor) {
    final theme = Theme.of(context);

    return _parseChoiceContent(choice.content, theme, textColor);
  }

  Widget _parseChoiceContent(String text, ThemeData theme, Color textColor) {
    // Always use TeXView for consistency
    return TeXView(
      child: TeXViewDocument(_buildTeXContent(text)),
      style: TeXViewStyle(
        contentColor: textColor,
        backgroundColor: Colors.transparent,
        textAlign: TeXViewTextAlign.left,
      ),
    );
  }

  String _buildTeXContent(String text) {
    // Convert LaTeX expressions to proper TeX format
    String processedText = text;

    // Handle display math ($$...$$)
    processedText = processedText.replaceAllMapped(
      RegExp(r'\$\$([^$]+)\$\$'),
      (match) =>
          '<div style="text-align: center; font-size: 16px; margin: 4px 0;">\\(${match.group(1)}\\)</div>',
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

// Helper widget for displaying choices in a list
class ChoiceList extends StatelessWidget {
  final List<Choice> choices;
  final int? selectedChoiceId;
  final int? correctChoiceId;
  final bool showAnswers;
  final Function(Choice)? onChoiceSelected;
  final bool isInteractive;

  const ChoiceList({
    super.key,
    required this.choices,
    this.selectedChoiceId,
    this.correctChoiceId,
    this.showAnswers = false,
    this.onChoiceSelected,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: choices.asMap().entries.map((entry) {
        final index = entry.key;
        final choice = entry.value;
        final choiceLabel = String.fromCharCode(65 + index); // A, B, C, D...

        ChoiceState state = ChoiceState.unselected;

        if (showAnswers && correctChoiceId != null) {
          if (choice.id == correctChoiceId) {
            state = ChoiceState.correct;
          } else if (choice.id == selectedChoiceId &&
              choice.id != correctChoiceId) {
            state = ChoiceState.incorrect;
          } else {
            state = ChoiceState.disabled;
          }
        } else if (choice.id == selectedChoiceId) {
          state = ChoiceState.selected;
        }

        return ChoiceCard(
          choice: choice,
          choiceLabel: choiceLabel,
          state: state,
          onTap: isInteractive ? () => onChoiceSelected?.call(choice) : null,
          isInteractive: isInteractive,
        );
      }).toList(),
    );
  }
}
