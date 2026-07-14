import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/flavors/flavor_config.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static void show() {
    Get.dialog(const PrivacyPolicyDialog(), barrierDismissible: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      '1. Information We Collect',
                      'We collect the following information:\n\n'
                          '• Personal Information: Name, phone number, grade/academic level\n'
                          '• Device Information: Device ID, brand, model, manufacturer, operating system\n'
                          '• Profile Data: Profile pictures (if you choose to upload)\n'
                          '• Usage Data: Study plans, exam progress, downloaded content\n'
                          '• Payment Information: Payment receipts and transaction records (if applicable)',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '2. How We Use Your Information',
                      'We use your information to:\n\n'
                          '• Provide and maintain ${FlavorConfig.appTitle} services\n'
                          '• Authenticate your account and prevent fraud\n'
                          '• Process your subscription payments\n'
                          '• Send study plan reminders and notifications\n'
                          '• Personalize your learning experience\n'
                          '• Store your downloaded study materials locally\n'
                          '• Improve our app and develop new features',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '3. Information Sharing and Data Storage',
                      'How We Share Data:\n\n'
                          '• We do not sell your personal information\n'
                          '• We may share data with trusted service providers (for example: cloud hosting, payment processing, analytics, crash reporting, and customer support) only to operate and improve the app\n'
                          '• These providers process data under contractual confidentiality and security obligations\n'
                          '• We may disclose information when required by law, legal process, or to protect users and platform security\n'
                          '• Data in transit is protected using HTTPS/TLS\n'
                          '• Study materials (PDFs, videos) are stored locally on your device',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '4. Data Security',
                      'Security Measures We Implement:\n\n'
                          '• HTTPS encryption for all data transmission\n'
                          '• Secure password storage with industry-standard hashing\n'
                          '• Device verification to prevent unauthorized access\n'
                          '• Regular security updates and monitoring\n\n'
                          'Please note: No internet transmission is 100% secure. We recommend using a strong password and keeping your device secure.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '5. Your Rights and Data Control',
                      'You Have Full Control:\n\n'
                          '• Access: View your personal data at any time\n'
                          '• Update: Edit your profile, phone number, and grade\n'
                          '• Delete: Permanently delete your account and associated data\n'
                          '• Download: Access downloaded study materials offline\n'
                          '• Opt-out: Disable notifications in app settings\n\n'
                          'To delete your account, go to Settings > Profile > Delete Account.\n'
                          'If you cannot access your account, contact support and request deletion from the Contact section below.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '6. Local Data Storage',
                      'App-Specific Storage:\n\n'
                          '• We store downloaded PDFs and videos locally on your device in app-specific directories\n'
                          '• Study plans and progress are cached locally for offline access\n'
                          '• Authentication tokens are stored securely using encrypted local storage\n'
                          '• We may use third-party SDKs (such as analytics/crash reporting) to improve app performance and reliability\n'
                          '• Clearing app data will remove all locally stored content\n'
                          '• Account-related server data is retained only as long as needed for service operation, legal compliance, and fraud prevention, then deleted or anonymized',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '7. Children\'s Privacy',
                      'Age Requirements:\n\n'
                          '• ${FlavorConfig.appTitle} is an educational platform designed for university freshman (first-year) students\n'
                          '• Our services are intended for students aged 13 and above\n'
                          '• We do not knowingly collect information from children under 13\n'
                          '• Parents/guardians should supervise usage for younger students\n'
                          '• If we discover we have collected data from a child under 13, we will delete it immediately',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '8. Notifications and Permissions',
                      'App Permissions Explained:\n\n'
                          '• Notifications: For study plan reminders and important updates\n'
                          '• Alarms & Reminders: To send precise scheduled notifications for your study plans\n'
                          '• Camera/Photos: Only when you choose to upload a profile picture (optional)\n'
                          '• Files/Media Access (where required by your Android version): For downloading and storing study materials locally\n\n'
                          'All permissions are requested only when needed and can be revoked in device settings.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '9. Changes to This Policy',
                      'We may update this Privacy Policy from time to time. We will post updates in the app and on our website before or when changes take effect.\n\n'
                          'Last Updated: April 2026',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '10. Contact Us',
                      'Questions or Concerns?\n\n'
                          'If you have any questions about this Privacy Policy or how we handle your data, please contact us:\n\n'
                          '• Through the support section in the app\n'
                          '• Via our website: freshmantricks.com\n'
                          '• Email: support@freshmantricks.com\n'
                          '• For account/data deletion requests, include your registered phone number and account details so we can verify ownership\n\n'
                          'We typically respond within 48 hours.',
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
      ],
    );
  }
}
