import 'package:flutter/material.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

/// Paper AppBar + body shell — replaces Entrance-style full-bleed gradients.
class FreshmanPageScaffold extends StatelessWidget {
  const FreshmanPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
    this.embeddedInTab = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;
  final bool embeddedInTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: false,
        leading: (showBack && !embeddedInTab)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => safePop(context: context),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurfaceVariant,
                ),
              ),
          ],
        ),
        titleSpacing: embeddedInTab || !showBack ? 20 : 0,
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class FreshmanSurfaceCard extends StatelessWidget {
  const FreshmanSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: card,
      ),
    );
  }
}
