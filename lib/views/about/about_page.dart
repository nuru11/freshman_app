import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/flavors/flavor_config.dart';
import 'package:vector_academy/config/support_config.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => packageInfo = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FreshmanPageScaffold(
      title: 'About',
      subtitle: FlavorConfig.appTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          FreshmanSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FlavorConfig.appTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'University first-year courses & study materials',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${FlavorConfig.appTitle} helps university freshman students succeed in first-year courses with lecture materials, practice quizzes, notes, and a study planner — not high-school entrance exam prep.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FreshmanSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mission', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Make high-quality university first-year course materials accessible to every freshman student.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Text('Vision', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Be the go-to companion for Ethiopian university freshmen through organized courses and study planning.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FreshmanSurfaceCard(
            child: Column(
              children: [
                _contactRow(
                  context,
                  Icons.email_outlined,
                  'Email',
                  supportEmail,
                  () => launchUrl(Uri.parse(supportEmailUrl)),
                ),
                const Divider(height: 20),
                _contactRow(
                  context,
                  Icons.phone_outlined,
                  'Phone',
                  supportPhoneNumber,
                  () => launchUrl(Uri.parse(supportPhoneUrl)),
                ),
                const Divider(height: 20),
                _contactRow(
                  context,
                  Icons.language,
                  'Website',
                  supportWebsiteHost,
                  () => launchUrl(
                    Uri.parse(supportWebsiteUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FreshmanSurfaceCard(
            child: Column(
              children: [
                _infoRow(
                  context,
                  'Version',
                  packageInfo?.version ?? '…',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  context,
                  'Build',
                  packageInfo?.buildNumber ?? '…',
                ),
                const SizedBox(height: 12),
                Text(
                  '© ${DateTime.now().year} ${FlavorConfig.appTitle}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
