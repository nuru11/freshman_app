import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/config/support_config.dart';
import 'package:vector_academy/controllers/study_hub/reading_plan_controller.dart';
import 'package:vector_academy/utils/snackbar_utils.dart';

class ReadingPlanTab extends StatelessWidget {
  const ReadingPlanTab({super.key});

  Future<void> _open(String url, String label) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      AppSnackbar.showError('Error', 'Unable to open $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReadingPlanController>(
      builder: (controller) {
        return RefreshIndicator(
          onRefresh: controller.load,
          color: primaryColor,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              FreshmanSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1-on-1 reading plans',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plans are prepared after a call or Telegram chat with admin. '
                      'Share your Telegram handle so they can reach you, then open '
                      'the PDF they send here — even offline after the first download.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.telegram),
                      title: const Text('Telegram'),
                      subtitle: const Text(supportTelegramHandle),
                      onTap: () => _open(supportTelegramUrl, 'Telegram'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone'),
                      subtitle: const Text(supportPhoneNumber),
                      onTap: () => _open(supportPhoneUrl, 'Phone'),
                    ),
                    TextField(
                      controller: controller.telegramController,
                      decoration: const InputDecoration(
                        labelText: 'Your Telegram username',
                        hintText: 'username (without @)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: controller.savingTelegram
                            ? null
                            : controller.saveTelegram,
                        child: Text(
                          controller.savingTelegram ? 'Saving…' : 'Save contact',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (controller.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (controller.documents.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    'No reading plan PDFs yet. Contact admin to get started.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...controller.documents.map((doc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FreshmanSurfaceCard(
                      onTap: () => controller.openDocument(doc),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            color: doc.isRead ? onSurfaceVariant : primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doc.isRead ? 'Read' : 'New',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: doc.isRead
                                        ? onSurfaceVariant
                                        : secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!doc.isRead)
                            TextButton(
                              onPressed: () => controller.markRead(doc),
                              child: const Text('Mark as Read'),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
