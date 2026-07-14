import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update the clear button
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadsController>(
      builder: (controller) => Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F4EF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => safePop(context: context),
          ),
          title: const Text('Downloads'),
          actions: [
            IconButton(
              onPressed: () => controller.refreshContent(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(context),
            Expanded(child: _buildTabContent(context, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTopBar(
    BuildContext context,
    DownloadsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Modern Back Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => safePop(context: context),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Title with Modern Typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Downloads',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your offline content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Clear Button - Updated to show options dialog
          GestureDetector(
            onTap: () => controller.showClearOptionsDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear_all_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF0B5F56).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF0B5F56),
        unselectedLabelColor: const Color(0xFF78716C),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_rounded, size: 18),
                SizedBox(width: 6),
                Text('Videos'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_rounded, size: 18),
                SizedBox(width: 6),
                Text('Quizzes'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_rounded, size: 18),
                SizedBox(width: 6),
                Text('Notes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    DownloadsController controller,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: [
          _VideosTab(controller: controller),
          _ExamsTab(controller: controller),
          _NotesTab(controller: controller),
        ],
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  final DownloadsController controller;

  const _VideosTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadsController>(
      builder: (controller) {
        if (controller.isLoadingVideos) {
          return _buildLoadingState('Loading videos...');
        }

        if (controller.allVideos.isEmpty) {
          return _buildEmptyState(
            icon: Icons.video_library_outlined,
            title: 'No Videos Available',
            subtitle: 'No videos found in your library',
          );
        }

        return Container(
          margin: const EdgeInsets.all(24),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: controller.allVideos.length,
            itemBuilder: (context, index) {
              final video = controller.allVideos[index];
              return _buildVideoItem(context, video, controller, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildVideoItem(
    BuildContext context,
    Video video,
    DownloadsController controller,
    int index,
  ) {
    final isLocked = controller.isVideoLocked(video);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: video.isDownloaded && !isLocked
                      ? () => controller.playVideo(video)
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Video Thumbnail with status
                        Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: isLocked
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [
                                      const Color(0xFF0F766E),
                                      const Color(0xFF0D9488),
                                    ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  isLocked
                                      ? Icons.lock_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              if (video.isDownloaded && !isLocked)
                                const Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.download_done,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                              if (video.isDownloading)
                                Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: video.downloadProgress,
                                      strokeWidth: 3,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Video Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      video.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isLocked)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 10,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'LOCKED',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${video.duration} minutes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : video.isDownloaded
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : video.isDownloading
                                          ? Colors.blue.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isLocked
                                          ? 'LOCKED'
                                          : video.isDownloaded
                                          ? 'DOWNLOADED'
                                          : video.isDownloading
                                          ? 'DOWNLOADING'
                                          : 'AVAILABLE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked
                                            ? Colors.orange
                                            : video.isDownloaded
                                            ? Colors.green
                                            : video.isDownloading
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (video.isDownloading) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(video.downloadProgress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          children: [
                            if (isLocked) ...[
                              IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ] else if (video.isDownloaded) ...[
                              IconButton(
                                onPressed: () => controller.playVideo(video),
                                icon: const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              IconButton(
                                onPressed: () => controller.deleteVideo(video),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                            ] else if (video.isDownloading) ...[
                              const IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.downloading_rounded,
                                  color: Colors.blue,
                                ),
                              ),
                            ] else ...[
                              IconButton(
                                onPressed: () =>
                                    controller.downloadVideo(video),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExamsTab extends StatelessWidget {
  final DownloadsController controller;

  const _ExamsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadsController>(
      builder: (controller) {
        if (controller.isLoadingExams) {
          return _buildLoadingState('Loading exams...');
        }

        var unlockedExams = controller.allExams
            .where((e) => !controller.isExamLocked(e))
            .toList();
        if (unlockedExams.isEmpty) {
          return _buildEmptyState(
            icon: Icons.quiz_outlined,
            title: 'No Exams Available',
            subtitle: 'No exams found in your library',
          );
        }

        return Container(
          margin: const EdgeInsets.all(24),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: unlockedExams.length,
            itemBuilder: (context, index) {
              final exam = unlockedExams[index];
              return _buildExamItem(context, exam, controller, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildExamItem(
    BuildContext context,
    Exam exam,
    DownloadsController controller,
    int index,
  ) {
    final isLocked = controller.isExamLocked(exam);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: exam.isDownloaded && !isLocked
                      ? () async => await controller.startExam(exam)
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Exam Icon with status
                        Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: isLocked
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [
                                      const Color(0xFF14B8A6),
                                      const Color(0xFFf5576c),
                                    ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  isLocked
                                      ? Icons.lock_rounded
                                      : Icons.quiz_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              if (exam.isDownloaded && !isLocked)
                                const Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.download_done,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                              if (exam.isLoadingQuestion)
                                const Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Exam Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      exam.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isLocked)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 10,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'LOCKED',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                exam.examType,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // First row with status badge
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : exam.isDownloaded
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : exam.isLoadingQuestion
                                          ? Colors.blue.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      exam.isDownloaded
                                          ? 'DOWNLOADED'
                                          : exam.isLoadingQuestion
                                          ? 'DOWNLOADING'
                                          : 'AVAILABLE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: exam.isDownloaded
                                            ? Colors.green
                                            : exam.isLoadingQuestion
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (exam.isLoadingQuestion) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          children: [
                            if (isLocked) ...[
                              IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ] else if (exam.isDownloaded) ...[
                              IconButton(
                                onPressed: () async =>
                                    await controller.startExam(exam),
                                icon: const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              IconButton(
                                onPressed: () => controller.deleteExam(exam),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                            ] else if (exam.isLoadingQuestion) ...[
                              const IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.downloading_rounded,
                                  color: Colors.blue,
                                ),
                              ),
                            ] else ...[
                              IconButton(
                                onPressed: () => controller.downloadExam(exam),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final DownloadsController controller;

  const _NotesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadsController>(
      builder: (controller) {
        if (controller.isLoadingNotes) {
          return _buildLoadingState('Loading notes...');
        }

        if (controller.allNotes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.description_outlined,
            title: 'No Notes Available',
            subtitle: 'No notes found in your library',
          );
        }

        return Container(
          margin: const EdgeInsets.all(24),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: controller.allNotes.length,
            itemBuilder: (context, index) {
              final note = controller.allNotes[index];
              return _buildNoteItem(context, note, controller, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    Note note,
    DownloadsController controller,
    int index,
  ) {
    final isLocked = controller.isNoteLocked(note);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: note.isDownloaded && !isLocked
                      ? () => controller.openNote(note)
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Note Icon with status
                        Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: isLocked
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [
                                      const Color(0xFF4facfe),
                                      const Color(0xFF00f2fe),
                                    ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  isLocked
                                      ? Icons.lock_rounded
                                      : Icons.picture_as_pdf,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              if (note.isDownloaded && !isLocked)
                                const Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.download_done,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                              if (note.isDownloading)
                                Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: note.downloadProgress,
                                      strokeWidth: 3,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Note Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isLocked)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 10,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'LOCKED',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chapter ${note.chapter}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : note.isDownloaded
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : note.isDownloading
                                          ? Colors.blue.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isLocked
                                          ? 'LOCKED'
                                          : note.isDownloaded
                                          ? 'DOWNLOADED'
                                          : note.isDownloading
                                          ? 'DOWNLOADING'
                                          : 'AVAILABLE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked
                                            ? Colors.orange
                                            : note.isDownloaded
                                            ? Colors.green
                                            : note.isDownloading
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (note.isDownloading) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(note.downloadProgress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                  if (note.size != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${note.size} MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          children: [
                            if (isLocked) ...[
                              IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ] else if (note.isDownloaded) ...[
                              IconButton(
                                onPressed: () => controller.openNote(note),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  color: Color(0xFF4facfe),
                                ),
                              ),
                              IconButton(
                                onPressed: () => controller.deleteNote(note),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                            ] else if (note.isDownloading) ...[
                              const IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.downloading_rounded,
                                  color: Colors.blue,
                                ),
                              ),
                            ] else ...[
                              IconButton(
                                onPressed: () => controller.downloadNote(note),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
