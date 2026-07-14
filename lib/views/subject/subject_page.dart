import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vector_academy/controllers/subject/subject_controller.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/config/app_config.dart';

class SubjectPage extends StatefulWidget {
  const SubjectPage({super.key, this.embeddedInTab = false});

  final bool embeddedInTab;

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  @override
  Widget build(BuildContext context) {
    Get.put(SubjectController());
    return GetBuilder<SubjectController>(
      builder: (controller) {
        final yearName = controller.user?.grade.name ?? '$gradeLabel';

        return FreshmanPageScaffold(
          title: widget.embeddedInTab ? 'My $subjectsLabel' : yearName,
          subtitle: widget.embeddedInTab
              ? yearName
              : 'Select a ${subjectLabel.toLowerCase()} to continue',
          showBack: !widget.embeddedInTab,
          embeddedInTab: widget.embeddedInTab,
          body: controller.isLoading && controller.subjects.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => controller.loadSubjects(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: controller.subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final subject = controller.subjects[index];
                      return _CourseListRow(
                        subject: subject,
                        onTap: () =>
                            controller.navigateToSubjectDetail(subject.id),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _CourseListRow extends StatelessWidget {
  const _CourseListRow({
    required this.subject,
    required this.onTap,
  });

  final Subject subject;
  final VoidCallback onTap;

  bool get _hasIcon => subject.icon != null && subject.icon!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FreshmanSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: _hasIcon
                  ? CachedNetworkImage(
                      imageUrl: subject.icon!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (context, url) => Container(
                        color: primaryColor.withValues(alpha: 0.08),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${subject.chapters.length} chapters',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: primaryColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.menu_book_outlined,
        color: primaryColor,
      ),
    );
  }
}
