import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/components/ui/custom_cards.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;
  final VoidCallback? onImageTap;
  final bool showQuestionNumber;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    this.onImageTap,
    this.showQuestionNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          if (showQuestionNumber) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question $questionNumber of $totalQuestions',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (question.image != null)
                  IconButton(
                    onPressed: onImageTap,
                    icon: Icon(Icons.image),
                    tooltip: 'View Image',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
          ],

          // Question Content
          _buildQuestionContent(context),

          // Question Image
          if (question.image != null) ...[
            SizedBox(height: 20),
            _buildQuestionImage(context),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionContent(BuildContext context) {
    // final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 60),
      child: _questionView(question.content),
    );
  }

  Widget _buildQuestionImage(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onImageTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: question.image!,
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
              height: 200,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionView(String text) {
    return TeXView(
      child: TeXViewDocument(_buildTeXContent(text)),
      style: TeXViewStyle(
        contentColor: Colors.black,
        backgroundColor: Colors.transparent,
        textAlign: TeXViewTextAlign.left,
        padding: TeXViewPadding.all(8),
        margin: TeXViewMargin.all(0),
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
