import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/misc/faq.dart';
import 'package:vector_academy/components/components.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FAQController>(
      init: FAQController(),
      builder: (controller) {
        return FreshmanPageScaffold(
          title: 'FAQ',
          subtitle: 'Common questions about Freshman',
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => showSearch(
                context: context,
                delegate: FaqSearchDelegate(),
              ),
            ),
          ],
          body: controller.faqs.isEmpty
              ? Center(
                  child: Text(
                    'No FAQs available yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onSurfaceVariant,
                        ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: controller.faqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final faq = controller.faqs[index];
                    return FreshmanSurfaceCard(
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: Text(
                          faq.question,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faq.answer,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class FaqSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final controller = Get.find<FAQController>();
    final q = query.toLowerCase();
    final results = controller.faqs.where((f) {
      return f.question.toLowerCase().contains(q) ||
          f.answer.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No matching FAQs'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final faq = results[index];
        return ListTile(
          title: Text(faq.question),
          subtitle: Text(faq.answer, maxLines: 2, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }
}
