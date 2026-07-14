import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class LaTeXUtils {
  /// Detects if a text contains LaTeX expressions
  static bool containsLaTeX(String text) {
    final RegExp latexRegex = RegExp(r'\$([^$]+)\$');
    final RegExp displayLatexRegex = RegExp(r'\$\$([^$]+)\$\$');

    return latexRegex.hasMatch(text) || displayLatexRegex.hasMatch(text);
  }

  /// Renders LaTeX content using TeXView
  static Widget renderLaTeX(
    String content,
    Color textColor, {
    double? fontSize,
    TeXViewTextAlign textAlign = TeXViewTextAlign.left,
  }) {
    return TeXView(
      child: TeXViewDocument(_buildTeXContent(content)),
      style: TeXViewStyle(
        contentColor: textColor,
        backgroundColor: Colors.transparent,
        textAlign: textAlign,
      ),
    );
  }

  /// Builds TeX content by converting markdown-style LaTeX to TeXView format
  static String _buildTeXContent(String text) {
    final RegExp latexRegex = RegExp(r'\$([^$]+)\$');
    final RegExp displayLatexRegex = RegExp(r'\$\$([^$]+)\$\$');

    String processedText = text;

    // Replace display math ($$...$$) with TeXView display format
    processedText = processedText.replaceAllMapped(
      displayLatexRegex,
      (match) => r'$$\(' + match.group(1)! + r'\)$$',
    );

    // Replace inline math ($...$) with TeXView inline format
    processedText = processedText.replaceAllMapped(
      latexRegex,
      (match) => r'\(' + match.group(1)! + r'\)',
    );

    // Handle rich text formatting
    processedText = _processRichText(processedText);

    return processedText;
  }

  /// Processes rich text formatting (bold, italic, code) to HTML
  static String _processRichText(String text) {
    String processed = text;

    // Bold text: **text** -> <strong>text</strong>
    processed = processed.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );

    // Italic text: *text* -> <em>text</em>
    processed = processed.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => '<em>${match.group(1)}</em>',
    );

    // Code text: `text` -> <code>text</code>
    processed = processed.replaceAllMapped(
      RegExp(r'`(.*?)`'),
      (match) => '<code>${match.group(1)}</code>',
    );

    // Convert line breaks
    processed = processed.replaceAll('\n', '<br>');

    return processed;
  }

  /// Parses text and returns appropriate widget (TeXView or RichText)
  static Widget parseTextWithLaTeX(
    String text,
    ThemeData theme, {
    Color? textColor,
    bool isDisplayMath = false,
  }) {
    if (containsLaTeX(text)) {
      return renderLaTeX(
        text,
        textColor ?? theme.colorScheme.onSurface,
        textAlign: TeXViewTextAlign.left,
      );
    } else {
      return RichText(text: _parseInlineText(text, theme, textColor));
    }
  }

  /// Parses inline text for rich formatting (bold, italic, code)
  static TextSpan _parseInlineText(
    String text,
    ThemeData theme,
    Color? textColor,
  ) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicRegex = RegExp(r'\*(.*?)\*');
    final RegExp codeRegex = RegExp(r'`(.*?)`');

    int lastIndex = 0;

    // Handle bold text
    for (final Match match in boldRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: match.group(1)!,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Handle italic text
    for (final Match match in italicRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: match.group(1)!,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: textColor,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Handle code text
    for (final Match match in codeRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: match.group(1)!,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: textColor,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
