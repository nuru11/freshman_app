import 'package:flutter/material.dart';

class CustomBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeStatus status;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.text,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case BadgeStatus.success:
        backgroundColor = theme.colorScheme.secondary.withOpacity(0.1);
        textColor = theme.colorScheme.secondary;
        break;
      case BadgeStatus.warning:
        backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
        textColor = const Color(0xFFF59E0B);
        break;
      case BadgeStatus.error:
        backgroundColor = theme.colorScheme.error.withOpacity(0.1);
        textColor = theme.colorScheme.error;
        break;
      case BadgeStatus.info:
        backgroundColor = const Color(0xFF3B82F6).withOpacity(0.1);
        textColor = const Color(0xFF3B82F6);
        break;
      case BadgeStatus.neutral:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return CustomBadge(
      text: text,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }
}

enum BadgeStatus { success, warning, error, info, neutral }

class ProgressBadge extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? text;
  final Color? progressColor;
  final Color? backgroundColor;
  final double size;

  const ProgressBadge({
    super.key,
    required this.progress,
    this.text,
    this.progressColor,
    this.backgroundColor,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor:
                backgroundColor ?? theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(
              progressColor ?? theme.colorScheme.primary,
            ),
            strokeWidth: 4,
          ),
          Center(
            child: Text(
              text ?? '${(progress * 100).toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: size * 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showBadge;
  final Color? badgeColor;
  final double? size;

  const NotificationBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.showBadge = true,
    this.badgeColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!showBadge || count <= 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            width: size ?? 20,
            height: size ?? 20,
            decoration: BoxDecoration(
              color: badgeColor ?? theme.colorScheme.error,
              borderRadius: BorderRadius.circular((size ?? 20) / 2),
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (size ?? 20) * 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScoreBadge extends StatelessWidget {
  final int score;
  final int maxScore;
  final double size;

  const ScoreBadge({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = score / maxScore;

    Color getScoreColor() {
      if (percentage >= 0.8) return theme.colorScheme.secondary;
      if (percentage >= 0.6) return const Color(0xFFF59E0B);
      return theme.colorScheme.error;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: getScoreColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: getScoreColor(), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              score.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: getScoreColor(),
                fontWeight: FontWeight.w800,
                fontSize: size * 0.25,
              ),
            ),
            Text(
              '/$maxScore',
              style: theme.textTheme.labelSmall?.copyWith(
                color: getScoreColor(),
                fontSize: size * 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelBadge extends StatelessWidget {
  final int level;
  final String? label;
  final Color? color;
  final double size;

  const LevelBadge({
    super.key,
    required this.level,
    this.label,
    this.color,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color ?? theme.colorScheme.primary,
            (color ?? theme.colorScheme.primary).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: (color ?? theme.colorScheme.primary).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            Text(
              level.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
