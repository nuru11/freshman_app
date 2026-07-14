import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/exam/question_page_controller.dart';
import 'package:vector_academy/controllers/home/main_navigation_controller.dart';

class ExamResultPage extends StatelessWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;

  const ExamResultPage({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score Circle
              _buildScoreCircle(context),

              SizedBox(height: 40),

              // Congratulation Message
              _buildCongratulationMessage(context),

              SizedBox(height: 60),

              // Action Buttons
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCircle(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Score",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "$correctAnswers/$totalQuestions",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCongratulationMessage(BuildContext context) {
    double percentage = (correctAnswers / totalQuestions) * 100;
    String title;
    String message;
    Color titleColor;

    if (percentage >= 90) {
      title = "Outstanding!";
      message = "Exceptional performance! You're a true champion!";
      titleColor = Colors.green[600]!;
    } else if (percentage >= 80) {
      title = "Excellent!";
      message = "Great job! You've mastered this topic!";
      titleColor = Colors.blue[600]!;
    } else if (percentage >= 70) {
      title = "Well Done!";
      message = "Good work! You're on the right track!";
      titleColor = Colors.orange[600]!;
    } else if (percentage >= 60) {
      title = "Good Effort!";
      message = "Nice try! Keep practicing to improve!";
      titleColor = Colors.amber[600]!;
    } else if (percentage >= 50) {
      title = "Keep Trying!";
      message = "You're getting there! More practice will help!";
      titleColor = Colors.deepOrange[600]!;
    } else {
      title = "Don't Give Up!";
      message = "Every expert was once a beginner. Keep learning!";
      titleColor = Colors.red[600]!;
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
        SizedBox(height: 16),
        Text(
          "You scored $correctAnswers out of $totalQuestions (${percentage.toStringAsFixed(1)}%)",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Review Answers
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (Get.isRegistered<QuestionPageController>()) {
                Get.find<QuestionPageController>().reviewAnswers();
              }
              Get.back();
            },
            icon: Icon(Icons.quiz_outlined),
            label: Text('Review Answers'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        SizedBox(height: 12),

        // Back to Exams
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Get.until((route) => route.settings.name == '/home');
              Get.find<MainNavigationController>().changeIndex(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              "Back to Page",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
