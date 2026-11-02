import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/freshman_page_scaffold.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';
import 'package:vector_academy/controllers/exam/exam_controller.dart';
import 'package:vector_academy/controllers/misc/downloads_controller.dart';
import 'package:vector_academy/models/exam.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/exam/exam_detail_page.dart';
import 'package:vector_academy/views/exam/exam_my_results_section.dart';
import 'package:vector_academy/views/exam/exam_standings_section.dart';

class ExamPage extends StatelessWidget {
  const ExamPage({super.key});

  static const _sectionLabels = ['Exams', 'Standings', 'My Results'];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamController>(
      builder: (controller) => FreshmanPageScaffold(
        title: 'Exam',
        embeddedInTab: true,
        actions: controller.examSection == ExamSection.exams
            ? [
                IconButton(
                  onPressed: () => showSearch(
                    context: context,
                    delegate: ExamSearchDelegate(),
                  ),
                  icon: Icon(Icons.search, color: onSurfaceColor),
                ),
              ]
            : null,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionChips(context, controller),
              Expanded(
                child: switch (controller.examSection) {
                  ExamSection.exams =>
                    _ExamsSection(controller: controller),
                  ExamSection.standings => const ExamStandingsSection(),
                  ExamSection.myResults => const ExamMyResultsSection(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionChips(BuildContext context, ExamController controller) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: List.generate(_sectionLabels.length, (index) {
          final selected = controller.examSectionIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.selectExamSectionIndex(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryColor.withValues(alpha: 0.12)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? primaryColor : borderColor,
                      ),
                    ),
                    child: Text(
                      _sectionLabels[index],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected ? primaryColor : onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ExamsSection extends StatelessWidget {
  const _ExamsSection({required this.controller});

  final ExamController controller;

  @override
  Widget build(BuildContext context) {
    return buildExamBrowseGrid(
      context: context,
      controller: controller,
      isCategoryBrowse: true,
      groups: controller.categoryGroups,
      onTap: (group) {
        Get.to(
          () => ExamSectionsPage(
            categoryId: group.id,
            categoryName: group.name,
          ),
        );
      },
    );
  }
}

Widget buildExamSubjectCategories(
  BuildContext context,
  ExamController controller,
) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: controller.subjects.length,
        itemBuilder: (context, index) {
          final subject = controller.subjects[index];
          final isSelected = controller.selectedSubjectIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                controller.selectSubject(index);
                logger.i("Clicked on subject: ${subject.name}");
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[50],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(0xFF0F766E).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(Icons.check_circle, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                      ],
                      Text(
                        subject.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
}

Widget _buildExamList(
  BuildContext context,
  ExamController controller, {
  List<Exam>? exams,
  String title = 'Available Exams',
}) {
  final items = exams ?? controller.exams;
  if (controller.isLoading) {
    return Center(child: CircularProgressIndicator());
  }

  if (controller.error != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error loading exams',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            controller.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.refreshExams(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  if (items.isEmpty) {
    return RefreshIndicator(
      onRefresh: controller.refreshExams,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  controller.isOffline
                      ? 'No downloaded exams'
                      : 'No exams available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  controller.isOffline
                      ? 'No downloaded exams are available offline'
                      : 'Check back later for new exams',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => controller.refreshExams(),
              icon: Icon(Icons.refresh, color: Colors.black87, size: 20),
              tooltip: 'Refresh exams',
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshExams,
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final exam = items[index];
                return GetBuilder<DownloadsController>(
                  builder: (_) => _buildExamCard(context, exam, controller),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildExamCard(
  BuildContext context,
  Exam exam,
  ExamController controller,
) {
  final locked = controller.isExamLocked(exam);
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => controller.navigateToExamDetail(exam.id),
    child: Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: locked ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked
              ? Colors.grey.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: locked ? Colors.grey[300] : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.quiz,
                      color: locked
                          ? Colors.grey[500]
                          : Colors.blue[600],
                      size: 24,
                    ),
                  ),
                  if (locked)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock, color: Colors.white, size: 8),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: locked
                          ? Colors.grey[600]
                          : Colors.blue[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (controller.completedExamIds.contains(exam.id))
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Text(
                        "${exam.totalQuestions} Q",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Text(
                        "${exam.duration}m",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        exam.isDownloaded
                            ? Icons.download_done
                            : Icons.cloud_download,
                        size: 12,
                        color: exam.isDownloaded
                            ? Colors.green[600]
                            : Colors.orange[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        exam.isDownloaded ? "Downloaded" : "Not Downloaded",
                        style: TextStyle(
                          fontSize: 11,
                          color: exam.isDownloaded
                              ? Colors.green[600]
                              : Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            SizedBox(width: 85, child: buildExamActionButton(exam, controller)),
          ],
        ),
      ),
    ),
  );
}

Widget buildExamActionButton(Exam exam, ExamController controller) {
  if (controller.isExamLocked(exam)) {
    return ElevatedButton(
      onPressed: () => openExamPurchase(exam),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: Size(0, 0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Flexible(
            child: Text(
              "Unlock",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  if (exam.isLoadingQuestion) {
    // Downloading exam
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[100],
        foregroundColor: Colors.orange[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: Size(0, 0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
            ),
          ),
          SizedBox(width: 3),
          Flexible(
            child: Text(
              "Loading",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  final backgroundColor = exam.isDownloaded
      ? Colors.green[600]
      : Colors.blue[600];
  final icon = exam.isDownloaded ? Icons.open_in_new : Icons.info;
  final label = exam.isDownloaded ? 'Open' : 'Details';

  return ElevatedButton(
    onPressed: () => controller.navigateToExamDetail(exam.id),
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      minimumSize: Size(0, 0),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 10, color: Colors.white),
        SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class ExamSearchDelegate extends SearchDelegate<Exam?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.close),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final controller = Get.find<ExamController>();
    return FutureBuilder<List<Exam>>(
      future: controller.searchExams(query),
      builder: (context, snapshot) {
        return snapshot.data?.isEmpty ?? true
            ? _buildNoResultsState(context)
            : _buildSearchResults(context, snapshot.data!);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final controller = Get.find<ExamController>();
    final exams = controller.exams
        .where((exam) => exam.examCategory != null)
        .toList();
    return ListView.builder(
      itemCount: exams.length,
      itemBuilder: (context, index) =>
          _buildExamCard(context, exams[index], controller),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(child: Text('No results found'));
  }

  Widget _buildSearchResults(BuildContext context, List<Exam> exams) {
    final controller = Get.find<ExamController>();
    return ListView.builder(
      itemCount: exams.length,
      itemBuilder: (context, index) =>
          _buildExamCard(context, exams[index], controller),
    );
  }
}

class _OfflineCategoryEmpty extends StatelessWidget {
  const _OfflineCategoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No saved exam categories',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Open Exams once while online to save categories for offline use.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

Widget buildExamBrowseGrid({
  required BuildContext context,
  required ExamController controller,
  required List<ExamBrowseGroup> groups,
  required void Function(ExamBrowseGroup group) onTap,
  bool compact = false,
  bool isCategoryBrowse = false,
  String emptyLabel = 'No exams available',
}) {
  if (controller.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (controller.error != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(controller.error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.refreshExams,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  if (groups.isEmpty) {
    return RefreshIndicator(
      onRefresh: controller.refreshExams,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Center(
              child: controller.isOffline && isCategoryBrowse && !compact
                  ? const _OfflineCategoryEmpty()
                  : Text(
                      emptyLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  if (compact) {
    return RefreshIndicator(
      onRefresh: controller.refreshExams,
      child: ListView.separated(
        clipBehavior: Clip.hardEdge,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _ExamSectionRow(group: group, onTap: () => onTap(group));
        },
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: controller.refreshExams,
    child: GridView.builder(
      clipBehavior: Clip.hardEdge,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _ExamBrowseCard(group: group, onTap: () => onTap(group));
      },
    ),
  );
}

class _ExamBrowseCard extends StatefulWidget {
  const _ExamBrowseCard({required this.group, required this.onTap});

  final ExamBrowseGroup group;
  final VoidCallback onTap;

  @override
  State<_ExamBrowseCard> createState() => _ExamBrowseCardState();
}

class _ExamBrowseCardState extends State<_ExamBrowseCard> {
  bool _imageFailed = false;

  bool get _hasThumbnail {
    final thumbnail = widget.group.thumbnail?.trim();
    return thumbnail != null && thumbnail.isNotEmpty && !_imageFailed;
  }

  String get _countLabel {
    final count = widget.group.count;
    return count == 1 ? '1 exam' : '$count exams';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _media()),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _countLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _media() {
    if (!_hasThumbnail) {
      return _iconArea();
    }

    return CachedNetworkImage(
      imageUrl: widget.group.thumbnail!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => _iconArea(showSpinner: true),
      errorWidget: (context, url, error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_imageFailed) {
            setState(() => _imageFailed = true);
          }
        });
        return _iconArea();
      },
    );
  }

  Widget _iconArea({bool showSpinner = false}) {
    return ColoredBox(
      color: primaryColor.withValues(alpha: 0.08),
      child: Center(
        child: showSpinner
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryColor,
                ),
              )
            : Icon(Icons.quiz_outlined, size: 32, color: primaryColor),
      ),
    );
  }
}

class _ExamSectionRow extends StatelessWidget {
  const _ExamSectionRow({required this.group, required this.onTap});

  final ExamBrowseGroup group;
  final VoidCallback onTap;

  String get _countLabel {
    final count = group.count;
    return count == 1 ? '1 exam' : '$count exams';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    group.isLocked ? Icons.lock_outline : Icons.quiz_outlined,
                    size: 22,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onSurfaceColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _countLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExamSectionsPage extends StatelessWidget {
  const ExamSectionsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int? categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamController>(
      builder: (controller) => Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          title: Text(
            categoryName,
            style: TextStyle(
              color: onSurfaceColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: surfaceColor,
          elevation: 0,
          iconTheme: IconThemeData(color: onSurfaceColor),
        ),
        body: SafeArea(
          child: buildExamBrowseGrid(
            context: context,
            controller: controller,
            compact: true,
            emptyLabel: 'No sections available',
            groups: controller.sectionsForCategory(categoryId: categoryId),
            onTap: (group) {
              final id = categoryId;
              if (group.isLocked && id != null) {
                openCategoryPurchase(
                  categoryId: id,
                  categoryName: categoryName,
                );
                return;
              }
              Get.to(
                () => ExamSectionExamsPage(
                  categoryId: categoryId,
                  sectionId: group.id,
                  sectionName: group.name,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ExamSectionExamsPage extends StatelessWidget {
  const ExamSectionExamsPage({
    super.key,
    required this.categoryId,
    required this.sectionId,
    required this.sectionName,
  });

  final int? categoryId;
  final int? sectionId;
  final String sectionName;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamController>(
      builder: (controller) => Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          title: Text(
            sectionName,
            style: TextStyle(
              color: onSurfaceColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: surfaceColor,
          elevation: 0,
          iconTheme: IconThemeData(color: onSurfaceColor),
        ),
        body: SafeArea(
          child: Column(
            children: [
              buildExamSubjectCategories(context, controller),
              Expanded(
                child: _buildExamList(
                  context,
                  controller,
                  exams: controller.examsInSection(
                    categoryId: categoryId,
                    sectionId: sectionId,
                  ),
                  title: sectionName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
