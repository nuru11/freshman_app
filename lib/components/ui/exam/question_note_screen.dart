import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/latex_utils.dart';

class QuestionNoteScreen extends StatelessWidget {
  final Question question;

  const QuestionNoteScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText =
        question.instruction != null && question.instruction!.trim().isNotEmpty;
    final hasImage = question.instructionImage != null &&
        question.instructionImage!.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Note',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasText)
                              _buildNoteText(context, question.instruction!),
                            if (hasImage) ...[
                              if (hasText) const SizedBox(height: 16),
                              _buildNoteImage(context),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildNoteText(BuildContext context, String instruction) {
    final theme = Theme.of(context);

    if (LaTeXUtils.containsLaTeX(instruction)) {
      return TeXWidget(
        key: ValueKey('note_${question.id}'),
        math: instruction,
      );
    }

    return Text(
      instruction,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
        height: 1.5,
      ),
    );
  }

  Widget _buildNoteImage(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: question.instructionImage!,
        width: double.infinity,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          height: 200,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 120,
          color: theme.colorScheme.errorContainer,
          child: Center(
            child: Text(
              'Failed to load image',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ),
      ),
    );
  }
}
