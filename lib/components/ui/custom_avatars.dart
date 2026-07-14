import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final Widget? child;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final Widget? badge;
  final BorderRadius? borderRadius;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.child,
    this.size = 48,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.badge,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary,
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      ),
      child:
          child ??
          (imageUrl != null
              ? ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
                  child: Image.network(
                    imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildInitialsAvatar(theme),
                  ),
                )
              : _buildInitialsAvatar(theme)),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    if (badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(bottom: 0, right: 0, child: badge!),
        ],
      );
    }

    return avatar;
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    return Center(
      child: Text(
        initials ?? '?',
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAvatar(
      imageUrl: imageUrl,
      initials: _getInitials(name),
      size: size,
      onTap: onTap,
      badge: isOnline
          ? Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(size * 0.125),
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            )
          : null,
    );
  }

  String _getInitials(String name) {
    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }
}

class GroupAvatar extends StatelessWidget {
  final List<String> names;
  final List<String?> imageUrls;
  final double size;
  final int maxVisible;
  final VoidCallback? onTap;

  const GroupAvatar({
    super.key,
    required this.names,
    this.imageUrls = const [],
    this.size = 48,
    this.maxVisible = 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleCount = names.length > maxVisible ? maxVisible : names.length;
    final remainingCount = names.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (visibleCount - 1) * (size * 0.3),
        height: size,
        child: Stack(
          children: [
            for (int i = 0; i < visibleCount; i++)
              Positioned(
                left: i * (size * 0.3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size / 2),
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: CustomAvatar(
                    imageUrl: i < imageUrls.length ? imageUrls[i] : null,
                    initials: _getInitials(names[i]),
                    size: size * 0.8,
                    backgroundColor: _getColorForIndex(i, theme),
                  ),
                ),
              ),
            if (remainingCount > 0)
              Positioned(
                left: visibleCount * (size * 0.3),
                child: Container(
                  width: size * 0.8,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(size * 0.4),
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: size * 0.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  Color _getColorForIndex(int index, ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }
}

class IconAvatar extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? badge;

  const IconAvatar({
    super.key,
    required this.icon,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAvatar(
      size: size,
      backgroundColor:
          backgroundColor ?? theme.colorScheme.primary.withOpacity(0.1),
      onTap: onTap,
      badge: badge,
      child: Icon(
        icon,
        size: size * 0.5,
        color: iconColor ?? theme.colorScheme.primary,
      ),
    );
  }
}
