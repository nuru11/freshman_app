import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsAndConditionsDialog extends StatelessWidget {
  const TermsAndConditionsDialog({super.key});

  static void show() {
    Get.dialog(
      const TermsAndConditionsDialog(),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  Icon(
                    Icons.description,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Terms and Conditions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
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
                      '1. Acceptance of Terms',
                      'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '2. Use License',
                      'Permission is granted to temporarily download one copy of the materials on the application for personal, non-commercial transitory viewing only.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '3. User Account',
                      'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '4. Content',
                      'All content provided on this application is for informational purposes only. We reserve the right to modify or remove content at any time without notice.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '5. Prohibited Uses',
                      'You may not use this application in any way that causes, or may cause, damage to the application or impairment of the availability or accessibility of the application.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '6. Limitation of Liability',
                      'In no event shall the application or its suppliers be liable for any damages arising out of the use or inability to use the materials on the application.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '7. Revisions',
                      'We may revise these terms of service at any time without notice. By using this application you are agreeing to be bound by the then current version of these terms of service.',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      '8. Contact Information',
                      'If you have any questions about these Terms and Conditions, please contact us through the support section of the application.',
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
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

