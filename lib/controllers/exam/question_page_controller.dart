import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/views/exam/exam_result_page.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/utils.dart';

enum QuestionMode { practice, exam }

class QuestionPageController extends GetxController {
  // Observable variables
  final RxInt currentQuestionIndex = 0.obs;
  final RxList<int?> userAnswers = <int?>[].obs;
  final RxInt timeRemaining = 0.obs;
  final RxBool isCompleted = false.obs;
  final RxBool showAnswers = false.obs;
  final RxBool showSolution = false.obs;
  final RxBool isSubmitting = false.obs; // Track submission status
  final RxBool showingNoteInterstitial = false.obs;
  final RxList<bool> submittedQuestions =
      <bool>[].obs; // Track which questions have been submitted

  int? noteBlockStartIndex;

  // Timer
  Timer? _timer;

  // Widget parameters
  late String title;
  late int initialTimeMinutes;
  late List<Question> questions;
  late Function(List<int> answers, int timeSpent)? onComplete;
  late bool allowReview;
  late bool showTimer;
  late QuestionMode mode;
  late int examId;
  late String examModeType; // Track exam mode type
  final HiveExamStorage _examStorage = HiveExamStorage();
  final ExamService _examService = ExamService();

  bool _isInitialized = false;
  int? _initializedExamId;
  int? _initializedQuestionCount;

  void initializeQuiz({
    required String title,
    required int initialTimeMinutes,
    required List<Question> questions,
    Function(List<int> answers, int timeSpent)? onComplete,
    bool allowReview = true,
    bool showTimer = true,
    QuestionMode mode = QuestionMode.exam,
    int examId = 0,
    String examModeType = 'both',
  }) {
    // Skip re-init on rebuilds (e.g. returning from ExamResultPage) so
    // answers, timer, and review state are not wiped.
    if (_isInitialized &&
        _initializedExamId == examId &&
        _initializedQuestionCount == questions.length) {
      this.onComplete = onComplete;
      this.allowReview = allowReview;
      this.showTimer = showTimer;
      this.mode = mode;
      this.examModeType = examModeType;
      return;
    }

    this.title = title;
    this.initialTimeMinutes = initialTimeMinutes;
    this.questions = questions;
    this.onComplete = onComplete;
    this.allowReview = allowReview;
    this.showTimer = showTimer;
    this.mode = mode;
    this.examId = examId;
    this.examModeType = examModeType;

    _timer?.cancel();

    // Handle empty questions
    if (questions.isEmpty) {
      userAnswers.value = [];
      timeRemaining.value = 0;
      submittedQuestions.value = [];
      _isInitialized = true;
      _initializedExamId = examId;
      _initializedQuestionCount = 0;
      return;
    }

    userAnswers.value = List.filled(questions.length, null);
    submittedQuestions.value = List.filled(questions.length, false);
    timeRemaining.value = initialTimeMinutes * 60;
    isCompleted.value = false;
    showAnswers.value = false;
    showSolution.value = false;
    isSubmitting.value = false;
    _clearNoteInterstitial();
    currentQuestionIndex.value = 0;
    _restoreProgressIfAny().whenComplete(
      _maybeShowNoteInterstitialForCurrentIndex,
    );
    if (showTimer) {
      _startTimer();
    }

    _isInitialized = true;
    _initializedExamId = examId;
    _initializedQuestionCount = questions.length;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeRemaining.value > 0) {
        timeRemaining.value--;
      } else {
        _timeUp();
      }
    });
  }

  void _timeUp() {
    _timer?.cancel();
    isCompleted.value = true;
    _showTimeUpDialog();
  }

  void _showTimeUpDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Time\'s Up!'),
        content: Text(
          'The time limit has been reached. Your answers will be submitted automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              submitQuiz();
            },
            child: Text('Submit'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void selectAnswer(int choiceId) {
    // Block changing answers once finished or in review for both modes
    if (isCompleted.value || showAnswers.value) {
      return;
    }
    // Additionally, in practice mode during the attempt, once an answer
    // is chosen for the current question, prevent changing it.
    if (mode == QuestionMode.practice &&
        userAnswers.isNotEmpty &&
        userAnswers[currentQuestionIndex.value] != null) {
      return;
    }
    userAnswers[currentQuestionIndex.value] = choiceId;
    update();
    _persistProgress();
  }

  void previousQuestion() {
    if (questions.isEmpty) return;

    if (showingNoteInterstitial.value) {
      if (noteBlockStartIndex != null && noteBlockStartIndex! > 0) {
        currentQuestionIndex.value = noteBlockStartIndex! - 1;
      }
      _clearNoteInterstitial();
      showSolution.value = false;
      update();
      _persistProgress();
      return;
    }

    final current = currentQuestionIndex.value;
    if (current <= 0) return;

    if (Question.isNoteBlockStart(questions, current)) {
      noteBlockStartIndex = current;
      showingNoteInterstitial.value = true;
      showSolution.value = false;
      update();
      return;
    }

    currentQuestionIndex.value--;
    showSolution.value = false; // Reset solution state when navigating
    update();
    _persistProgress();
  }

  void nextQuestion() async {
    if (questions.isEmpty) return;

    if (showingNoteInterstitial.value) {
      if (noteBlockStartIndex != null) {
        currentQuestionIndex.value = noteBlockStartIndex!;
      }
      _clearNoteInterstitial();
      showSolution.value = false;
      update();
      _persistProgress();
      return;
    }

    if (currentQuestionIndex.value >= questions.length - 1) {
      return;
    }

    final nextIndex = currentQuestionIndex.value + 1;
    if (Question.isNoteBlockStart(questions, nextIndex)) {
      noteBlockStartIndex = nextIndex;
      showingNoteInterstitial.value = true;
      showSolution.value = false;
      update();
      return;
    }

    currentQuestionIndex.value++;
    showSolution.value = false; // Reset solution state when navigating
    update();
    _persistProgress();
  }

  Question? get noteInterstitialQuestion {
    if (noteBlockStartIndex == null) return null;
    if (noteBlockStartIndex! < 0 || noteBlockStartIndex! >= questions.length) {
      return null;
    }
    return questions[noteBlockStartIndex!];
  }

  void _clearNoteInterstitial() {
    showingNoteInterstitial.value = false;
    noteBlockStartIndex = null;
  }

  /// Show note screen when landing on a note-block start (including Q1).
  void _maybeShowNoteInterstitialForCurrentIndex() {
    if (isCompleted.value || showAnswers.value || questions.isEmpty) return;
    final index = currentQuestionIndex.value;
    if (!Question.isNoteBlockStart(questions, index)) return;
    noteBlockStartIndex = index;
    showingNoteInterstitial.value = true;
    update();
  }

  /// Check if next button should be enabled
  bool get canMoveToNext {
    if (showingNoteInterstitial.value) return true;
    // In review mode, allow navigating freely (including skipped questions)
    if (showAnswers.value) return true;

    if (userAnswers[currentQuestionIndex.value] == null) {
      return false; // No answer selected
    }

    // Just need an answer selected, no submission required
    return true;
  }

  bool get canMoveToPrevious {
    if (showingNoteInterstitial.value) {
      return noteBlockStartIndex != null && noteBlockStartIndex! > 0;
    }
    return currentQuestionIndex.value > 0;
  }

  void goToQuestion(int index) {
    if (allowReview &&
        questions.isNotEmpty &&
        index >= 0 &&
        index < questions.length) {
      currentQuestionIndex.value = index;
      showSolution.value = false; // Reset solution state when navigating
    }
  }

  void submitQuiz() async {
    _timer?.cancel();

    final modeType = examModeType.toLowerCase();
    final isExamModeType =
        modeType == 'exam_mode' ||
        modeType == 'exam mode' ||
        modeType == 'both';

    // For exam_mode and both, require successful submission before navigation
    if (isExamModeType && examId != 0) {
      await _submitWithRetry();
    } else {
      // For other modes, proceed without submission requirement
      _navigateToResults();
    }
  }

  Future<void> _submitWithRetry() async {
    bool submissionSuccessful = false;

    while (!submissionSuccessful) {
      // Set submitting state to show loading indicator
      isSubmitting.value = true;
      update();

      try {
        // Submit all answers at once using bulk endpoint
        if (examId != 0 && questions.isNotEmpty) {
          final user = await HiveUserStorage().getUser();
          if (user != null) {
            final device = await UserDevice.getDeviceInfo(user.phoneNumber);

            // Prepare bulk answers list
            final List<Map<String, int>> bulkAnswers = [];
            for (int i = 0; i < questions.length; i++) {
              final answer = userAnswers[i];
              if (answer != null) {
                final question = questions[i];
                bulkAnswers.add({'question': question.id, 'answer': answer});
              }
            }

            if (bulkAnswers.isNotEmpty) {
              logger.i(
                'Submitting ${bulkAnswers.length} answers in bulk for examId=$examId',
              );
              await _examService.submitBulkAnswers(
                device.id,
                examId,
                bulkAnswers,
              );
              logger.i(
                'Successfully submitted all ${bulkAnswers.length} answers',
              );
              submissionSuccessful = true;
            } else {
              logger.w('No answers to submit');
              // If no answers, still proceed (user might have skipped all)
              submissionSuccessful = true;
            }
          } else {
            throw Exception('User not found');
          }
        } else {
          // No exam ID, proceed without submission
          submissionSuccessful = true;
        }
      } catch (e) {
        logger.e('Error during final submission: $e');
        isSubmitting.value = false;
        update();

        // Show retry dialog
        final shouldRetry = await _showRetryDialog(e.toString());
        if (!shouldRetry) {
          // User chose not to retry, but we still need to block navigation
          // Keep the dialog open or show error
          return;
        }
        // Continue loop to retry
      }
    }

    // Only navigate if submission was successful
    if (submissionSuccessful) {
      isSubmitting.value = false;
      update();
      _navigateToResults();
    }
  }

  Future<bool> _showRetryDialog(String errorMessage) async {
    bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Submission Failed'),
        content: Text(
          'Failed to submit your answers. Please check your internet connection and try again.\n\nError: ${errorMessage.length > 100 ? "${errorMessage.substring(0, 100)}..." : errorMessage}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Retry'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  void _navigateToResults() {
    isCompleted.value = true;
    _examStorage.clearProgress(
      examId,
      mode == QuestionMode.practice ? 'practice' : 'exam',
    );
    _examStorage.markCompleted(examId);
    Get.to(
      () => ExamResultPage(
        score: calculateCorrectAnswers(),
        totalQuestions: questions.length,
        correctAnswers: calculateCorrectAnswers(),
      ),
    );
  }

  void reviewAnswers() {
    showAnswers.value = true;
    currentQuestionIndex.value = 0;
    update();
  }

  void finishQuiz() {
    // Results already shown after submit; exiting review should only leave the page.
    if (!isCompleted.value) {
      final timeSpent = (initialTimeMinutes * 60) - timeRemaining.value;
      // Replace nulls (skipped) with 0 so onComplete always receives List<int>
      final answers = userAnswers.map((a) => a ?? 0).toList();
      onComplete?.call(answers, timeSpent);
    }
    _safePop();
  }

  /// Pop without Get.back()'s snackbar teardown (can throw LateInitializationError).
  void _safePop() {
    final navigator = Get.key.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    try {
      Get.back();
    } catch (_) {
      // Ignore GetX snackbar teardown failures
    }
  }

  void toggleSolution() {
    showSolution.value = !showSolution.value;
    update();
  }

  int calculateCorrectAnswers() {
    if (questions.isEmpty) return 0;

    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      final userAnswer = userAnswers[i];
      if (userAnswer != null) {
        final question = questions[i];
        // Find the correct choice by checking isCorrect property
        final correctChoice = question.choices.firstWhereOrNull(
          (choice) => choice.isCorrect,
        );
        if (userAnswer == correctChoice?.id) {
          correct++;
        }
      }
    }
    return correct;
  }

  void showImageDialog(String? imageUrl) {
    if (imageUrl == null) return;

    Get.dialog(
      Dialog(
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Question Image'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Center(child: Text('Failed to load image')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showQuitDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Quit Quiz?'),
        content: Text(
          'Are you sure you want to quit? Your progress will be lost.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.back();
            },
            child: Text('Quit'),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    _persistProgress();
    super.onClose();
  }

  Future<void> _restoreProgressIfAny() async {
    if (examId == 0) return;
    final saved = await _examStorage.getProgress(
      examId,
      mode == QuestionMode.practice ? 'practice' : 'exam',
    );
    if (saved == null) return;

    final savedIndex = (saved['current_question_index'] as num?)?.toInt() ?? 0;
    final savedAnswers =
        (saved['selected_answers'] as List<dynamic>?)
            ?.map((e) => e == null ? null : (e as num).toInt())
            .toList() ??
        [];
    final savedRemaining = (saved['remaining_time'] as num?)?.toInt();

    if (savedAnswers.isNotEmpty && savedAnswers.length == questions.length) {
      userAnswers.value = List<int?>.from(savedAnswers);
    }
    currentQuestionIndex.value = savedIndex.clamp(
      0,
      (questions.length - 1).clamp(0, questions.length),
    );
    if (savedRemaining != null && savedRemaining > 0) {
      timeRemaining.value = savedRemaining;
    }
    // Do not override current mode; we load only the progress for the active mode
    update();
  }

  void _persistProgress() {
    if (examId == 0) return;
    _examStorage.saveProgress(
      examId,
      currentIndex: currentQuestionIndex.value,
      answers: userAnswers.toList(),
      timeRemaining: timeRemaining.value,
      mode: mode == QuestionMode.practice ? 'practice' : 'exam',
    );
  }
}
