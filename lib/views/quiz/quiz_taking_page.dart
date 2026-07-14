import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuizTakingPage extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const QuizTakingPage({super.key, required this.quiz});

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  int currentQuestionIndex = 0;
  int? selectedAnswer;
  List<int> userAnswers = [];

  // Mock questions for now
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is the meaning of physics in other sciences?',
      'options': [
        'User Interface and User Experience',
        'User Interface and User Experience',
        'User Interface and User Experience',
        'User Interface and User Experience',
        'User Interface and User Experience',
      ],
      'correctAnswer': 0,
    },
    {
      'question': 'Which branch of physics deals with motion?',
      'options': [
        'Mechanics',
        'Thermodynamics',
        'Electromagnetism',
        'Quantum Physics',
        'Optics',
      ],
      'correctAnswer': 0,
    },
    {
      'question': 'What is the SI unit of force?',
      'options': ['Newton', 'Joule', 'Watt', 'Pascal', 'Ampere'],
      'correctAnswer': 0,
    },
    {
      'question':
          'Which law states that every action has an equal and opposite reaction?',
      'options': [
        'Newton\'s First Law',
        'Newton\'s Second Law',
        'Newton\'s Third Law',
        'Law of Gravitation',
        'Law of Conservation of Energy',
      ],
      'correctAnswer': 2,
    },
    {
      'question': 'What is the formula for kinetic energy?',
      'options': ['KE = mgh', 'KE = ½mv²', 'KE = Fd', 'KE = Pt', 'KE = qV'],
      'correctAnswer': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    userAnswers = List.filled(questions.length, -1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Timer
            _buildTopBar(context),

            // Progress Indicator
            _buildProgressIndicator(context),

            // Question Card
            Expanded(child: _buildQuestionCard(context)),

            // Navigation Buttons
            _buildNavigationButtons(context),
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
            onTap: () => _showQuitDialog(context),
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

          // Quiz Title
          Expanded(
            child: Text(
              "Chapter One Quiz",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Timer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "16:35",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),

          SizedBox(height: 16),

          // Question Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(questions.length, (index) {
              final isCurrent = index == currentQuestionIndex;
              final isAnswered = userAnswers[index] != -1;

              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.blue[600]
                      : isAnswered
                      ? Colors.green[100]
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? Colors.blue[600]!
                        : isAnswered
                        ? Colors.green[600]!
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white
                          : isAnswered
                          ? Colors.green[600]
                          : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context) {
    final question = questions[currentQuestionIndex];

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            question['question'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 32),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount: question['options'].length,
              itemBuilder: (context, index) {
                final option = question['options'][index];
                final isSelected = selectedAnswer == index;
                final isAnswered = userAnswers[currentQuestionIndex] != -1;

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: isAnswered ? null : () => _selectAnswer(index),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[600] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue[600]!
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(
                                  65 + index,
                                ), // A, B, C, D, E
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue[600]
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          // Previous Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: currentQuestionIndex > 0
                  ? () => _previousQuestion()
                  : null,
              icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
              label: Text(
                "Previous",
                style: TextStyle(color: Colors.blue[600]),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.blue[600]!),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          // Next/Submit Button
          Expanded(
            child: ElevatedButton(
              onPressed: selectedAnswer != null ? () => _nextQuestion() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                currentQuestionIndex == questions.length - 1
                    ? "Submit Quiz"
                    : "Next",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      selectedAnswer = answerIndex;
      userAnswers[currentQuestionIndex] = answerIndex;
    });
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedAnswer = userAnswers[currentQuestionIndex];
      });
    }
  }

  void _nextQuestion() {
    if (selectedAnswer != null) {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedAnswer = userAnswers[currentQuestionIndex];
        });
      } else {
        // Submit quiz
        _submitQuiz();
      }
    }
  }

  void _submitQuiz() {
    // Calculate score
    int correctAnswers = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i]['correctAnswer']) {
        correctAnswers++;
      }
    }

    // Navigate to results page
    Get.off(
      () => QuizResultPage(
        score: correctAnswers,
        totalQuestions: questions.length,
        correctAnswers: correctAnswers,
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quit Quiz?'),
          content: Text(
            'Are you sure you want to quit? Your progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.back();
              },
              child: Text('Quit'),
            ),
          ],
        );
      },
    );
  }
}

// Quiz Result Page
class QuizResultPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;

  const QuizResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Congratulations Banner
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "CONGRATULATIONS!!!!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // Score Modal
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "YOUR SCORE IS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 20),

                      Text(
                        "$score/$totalQuestions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 30),

                      // Finish Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "FINISH",
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
