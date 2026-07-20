import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/exam/exam_controller.dart';
import 'package:vector_academy/controllers/misc/downloads_controller.dart';
import 'package:vector_academy/models/exam.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';

class ExamPage extends StatelessWidget {
  const ExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamController>(
      builder: (controller) => Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        appBar: AppBar(
          title: Text(
            'Exams',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFFF7F4EF),
          elevation: 0,
          automaticallyImplyLeading: false, // Change this line
          actions: [
            IconButton(
              onPressed: () =>
                  showSearch(context: context, delegate: ExamSearchDelegate()),
              icon: Icon(Icons.search, color: Colors.black87),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Subject Categories
              _buildSubjectCategories(context, controller),

              // Exam List - This will now take up most of the available space
              Expanded(child: _buildExamList(context, controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionalBanner(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ), // Reduced margins
      padding: EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Test Your Knowledge",
                  style: TextStyle(
                    fontSize: 16, // Smaller font
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6), // Reduced spacing
                Text(
                  "Practice with our comprehensive question bank",
                  style: TextStyle(
                    fontSize: 13, // Smaller font
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 12), // Reduced spacing
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement take exams functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7F4EF),
                      foregroundColor: Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ), // Smaller button
                    ),
                    child: Text(
                      "Start Practice",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12), // Reduced spacing
          Container(
            width: 60, // Smaller icon container
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.emoji_events,
              size: 30, // Smaller icon
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCategories(
    BuildContext context,
    ExamController controller,
  ) {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemCount: controller.subjects.length,
        itemBuilder: (context, index) {
          final subject = controller.subjects[index];
          final isSelected = controller.selectedSubjectIndex == index;

          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                controller.selectSubject(index);
                logger.i("Clicked on subject: ${subject.name}");
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
}

Widget _buildExamList(BuildContext context, ExamController controller) {
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

  if (controller.exams.isEmpty) {
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
                  'No exams available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Check back later for new exams',
                  style: TextStyle(color: Colors.grey[600]),
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
                  'Available Quizzes',
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
              itemCount: controller.exams.length,
              itemBuilder: (context, index) {
                final exam = controller.exams[index];
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
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => controller.navigateToExamDetail(exam.id),
    child: Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: exam.isLocked ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: exam.isLocked
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
                color: exam.isLocked ? Colors.grey[300] : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.quiz,
                      color: exam.isLocked
                          ? Colors.grey[500]
                          : Colors.blue[600],
                      size: 24,
                    ),
                  ),
                  if (exam.isLocked)
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
                      color: exam.isLocked
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
  if (exam.isLocked) {
    // Locked exam
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.grey[500],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: Size(0, 0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 10, color: Colors.grey[500]),
          SizedBox(width: 3),
          Flexible(
            child: Text(
              "Locked",
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
    return ListView.builder(
      itemCount: controller.exams.length,
      itemBuilder: (context, index) =>
          _buildExamCard(context, controller.exams[index], controller),
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
