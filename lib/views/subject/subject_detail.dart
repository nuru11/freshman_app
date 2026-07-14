import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/subject/subject_detail_controller.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/components/components.dart';

class SubjectDetail extends StatelessWidget {
  const SubjectDetail({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SubjectDetailController());

    return GetBuilder<SubjectDetailController>(
      builder: (controller) {
        final count = controller.chapters.length;
        final subtitle = controller.isLoading
            ? 'Loading units…'
            : '$count ${count == 1 ? 'chapter' : 'chapters'} · first unit free to preview';

        return FreshmanPageScaffold(
          title: controller.subjectName.isEmpty
              ? 'Course'
              : controller.subjectName,
          subtitle: subtitle,
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.chapters.isEmpty
                  ? Center(
                      child: Text(
                        'No chapters available yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: controller.chapters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final chapter = controller.chapters[index];
                        return _ChapterRow(
                          chapter: chapter,
                          locked: controller.isChapterLocked(chapter),
                          isPreview: controller.isPreviewChapter(chapter),
                          onTap: () => controller.handleChapterTap(chapter),
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.locked,
    required this.isPreview,
    required this.onTap,
  });

  final Chapter chapter;
  final bool locked;
  final bool isPreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = locked ? onSurfaceVariant : onSurfaceColor;
    final subtitle = locked
        ? 'Subscribe to unlock'
        : isPreview
            ? 'Preview free'
            : (chapter.description?.trim().isNotEmpty == true
                ? chapter.description!
                : 'Open unit');

    return FreshmanSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: locked
                  ? onSurfaceVariant.withValues(alpha: 0.1)
                  : primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Unit',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: locked ? onSurfaceVariant : primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${chapter.chapterNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: locked ? onSurfaceVariant : primaryColor,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.name,
                  style: theme.textTheme.titleSmall?.copyWith(color: titleColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: locked
                        ? secondaryColor
                        : isPreview
                            ? primaryColor
                            : onSurfaceVariant,
                    fontWeight:
                        locked || isPreview ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            locked ? Icons.lock_outline : Icons.chevron_right_rounded,
            color: locked ? onSurfaceVariant : secondaryColor,
            size: 22,
          ),
        ],
      ),
    );
  }
}
