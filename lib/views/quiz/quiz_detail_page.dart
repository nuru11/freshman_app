import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/utils/navigation_utils.dart';
import 'package:vector_academy/views/quiz/quiz_taking_page.dart';

class QuizDetailPage extends StatelessWidget {
  final Map<String, dynamic> quiz;

  const QuizDetailPage({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context),

            // Quiz Content
            Expanded(child: _buildQuizContent(context)),

            // Start Quiz Button
            _buildStartQuizButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => safePop(context: context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),

          SizedBox(width: 16),

          // Title
          Text(
            "Detail Quiz",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brief Explanation
          Text(
            "Brief explanation about this quiz",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 24),

          // Quiz Summary
          _buildQuizSummary(context),

          SizedBox(height: 32),

          // Instructions
          Text(
            "Please read the text below carefully so you can understand it",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 16),

          // Instructions List
          _buildInstructionsList(context),
        ],
      ),
    );
  }

  Widget _buildQuizSummary(BuildContext context) {
    return Column(
      children: [
        _buildSummaryItem(
          Icons.description,
          "10 Question",
          "10 point for a correct answer",
        ),

        SizedBox(height: 16),

        _buildSummaryItem(
          Icons.access_time,
          "1 hour 15 min",
          "Total duration of the quiz",
        ),

        SizedBox(height: 16),

        _buildSummaryItem(
          Icons.star,
          "Win 10 star",
          "Answer all questions correctly",
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue[600], size: 24),
        ),

        SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsList(BuildContext context) {
    final instructions = [
      "10 point awarded for a correct answer and no marks for a incorrect answer",
      "Tap on options to select the correct answer",
      "Tap on the bookmark icon to save interesting questions",
      "Click submit if you are sure you want to complete all the quizzes",
    ];

    return Column(
      children: instructions.map((instruction) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Text(
                  instruction,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartQuizButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _startQuiz(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Start Quiz",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz() {
    Get.to(() => QuizTakingPage(quiz: quiz));
  }
}
