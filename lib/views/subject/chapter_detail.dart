import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/subject/chapter_detail_controller.dart';
import 'package:vector_academy/views/tabs/video_tab.dart';
import 'package:vector_academy/views/tabs/notes_tab.dart';
import 'package:vector_academy/views/tabs/quiz_tab.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

class ChapterDetail extends StatelessWidget {
  const ChapterDetail({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ChapterDetailController());
    return GetBuilder<ChapterDetailController>(
      builder: (controller) => DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => safePop(context: context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.chapterTitle.isEmpty
                      ? 'Chapter'
                      : controller.chapterTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!controller.isLoading)
                  Text(
                    '${controller.videos.length} videos · '
                    '${controller.notes.length} notes · '
                    '${controller.quizzes.length} quizzes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: primaryColor,
                    unselectedLabelColor: onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline, size: 16),
                            SizedBox(width: 4),
                            Text('Videos'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 16),
                            SizedBox(width: 4),
                            Text('Notes'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, size: 16),
                            SizedBox(width: 4),
                            Text('Quizzes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: controller.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Loading unit content…',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : const TabBarView(
                  children: [
                    VideoTab(),
                    NotesTab(),
                    QuizTab(),
                  ],
                ),
        ),
      ),
    );
  }
}
