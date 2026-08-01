import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/utils/utils.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _openSupportLink(String url, String label) async {
    final uri = Uri.parse(url);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        AppSnackbar.showError('Error', 'Unable to open $label');
        return;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        AppSnackbar.showError('Error', 'Unable to open $label');
      }
    } catch (e) {
      AppSnackbar.showError('Error', 'Unable to open $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FreshmanPageScaffold(
      title: 'Support',
      subtitle: 'We are here to help',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Reach the Freshman team through any channel below.',
            style: theme.textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _SupportTile(
            icon: Icons.telegram,
            title: 'Telegram',
            subtitle: supportTelegramHandle,
            onTap: () => _openSupportLink(supportTelegramUrl, 'Telegram'),
          ),
          const SizedBox(height: 8),
          _SupportTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: supportEmail,
            onTap: () => _openSupportLink(supportEmailUrl, 'Email'),
          ),
          const SizedBox(height: 8),
          _SupportTile(
            icon: Icons.phone_outlined,
            title: 'Phone',
            subtitle: supportPhoneNumber,
            onTap: () => _openSupportLink(supportPhoneUrl, 'Phone'),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FreshmanSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: onSurfaceVariant),
        ],
      ),
    );
  }
}
