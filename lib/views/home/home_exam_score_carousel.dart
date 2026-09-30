import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/views/common/user_score_page.dart';

class HomeExamScoreCarousel extends StatefulWidget {
  const HomeExamScoreCarousel({super.key});

  @override
  State<HomeExamScoreCarousel> createState() => _HomeExamScoreCarouselState();
}

class _HomeExamScoreCarouselState extends State<HomeExamScoreCarousel> {
  static const double _cardHeight = 116;

  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<CompetetionExam> _visibleExams(UserScoreController controller) {
    final result = controller.userResult;
    if (result != null && result.hasUserAttempted) {
      return result.exams.isNotEmpty
          ? result.exams
          : controller.examFallbackScores;
    }
    return controller.examFallbackScores;
  }

  void _openMyScores() {
    Get.to(() => const UserScorePage());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserScoreController>(
      builder: (controller) {
        final exams = _visibleExams(controller);
        if (exams.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeIndex = _currentPage.clamp(0, exams.length - 1);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'My Scores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _openMyScores,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text(
                        'See all',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              if (exams.length == 1)
                SizedBox(
                  height: _cardHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                    child: _ExamScoreSlide(
                      exam: exams.first,
                      onTap: _openMyScores,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: _cardHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    clipBehavior: Clip.none,
                    padEnds: false,
                    itemCount: exams.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 20 : 6,
                          right: index == exams.length - 1 ? 20 : 6,
                          top: 2,
                          bottom: 8,
                        ),
                        child: _ExamScoreSlide(
                          exam: exams[index],
                          onTap: _openMyScores,
                        ),
                      );
                    },
                  ),
                ),
              if (exams.length > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(exams.length, (index) {
                    final isActive = index == activeIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ExamScoreSlide extends StatelessWidget {
  const _ExamScoreSlide({required this.exam, required this.onTap});

  final CompetetionExam exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percentage = exam.totalQuestions > 0
        ? ((exam.score / exam.totalQuestions) * 100).clamp(0.0, 100.0)
        : 0.0;
    final scoreColor = _scoreColor(percentage);
    final phrase = _scorePhrase(percentage);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.08),
            Colors.white,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.quiz_outlined,
                        size: 16,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.examName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '${exam.totalQuestions} Questions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${exam.score.toStringAsFixed(1)} / ${exam.totalQuestions}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  phrase,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _scorePhrase(double percentage) {
    if (percentage >= 90) return 'Excellent Work';
    if (percentage >= 70) return 'Great Job, Keep It Up';
    if (percentage >= 50) return 'You Are On The Right Track';
    if (percentage >= 30) return 'Keep Practicing';
    return 'You Need To Work More';
  }
}
