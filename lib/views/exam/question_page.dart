import 'package:vector_academy/utils/latex_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/controllers/exam/question_page_controller.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

class QuestionPage extends StatelessWidget {
  final String title;
  final int initialTimeMinutes;
  final List<Question> questions;
  final Function(List<int> answers, int timeSpent)? onComplete;
  final bool allowReview;
  final bool showTimer;
  final QuestionMode mode;
  final int examId;
  final String examModeType;

  const QuestionPage({
    super.key,
    required this.title,
    required this.initialTimeMinutes,
    required this.questions,
    this.onComplete,
    this.allowReview = true,
    this.showTimer = true,
    this.mode = QuestionMode.exam,
    this.examId = 0,
    this.examModeType = 'both',
  });

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(QuestionPageController());

    // Initialize the quiz data
    controller.initializeQuiz(
      title: title,
      initialTimeMinutes: initialTimeMinutes,
      questions: questions,
      onComplete: onComplete,
      allowReview: allowReview,
      showTimer: showTimer,
      mode: mode,
      examId: examId,
      examModeType: examModeType,
    );

    return GetBuilder<QuestionPageController>(
      builder: (controller) {
        // Handle empty questions state
        if (controller.questions.isEmpty) {
          return _buildEmptyQuestionsState(context, controller);
        }

        if (controller.isCompleted.value && !controller.showAnswers.value) {
          return _buildResultsPage(context, controller);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(context, controller),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timer if enabled
                  if (showTimer) _buildTimer(context, controller),

                  SizedBox(height: 16),

                  // Question content
                  _buildQuestionCard(
                    context,
                    controller.questions[controller.currentQuestionIndex.value],
                    controller.currentQuestionIndex.value + 1,
                  ),

                  SizedBox(height: 20),

                  // Choices
                  _buildChoicesSection(
                    context,
                    controller
                        .questions[controller.currentQuestionIndex.value]
                        .choices,
                    controller,
                  ),

                  SizedBox(height: 16),

                  // Solution Section
                  _buildSolutionSection(
                    context,
                    controller.questions[controller.currentQuestionIndex.value],
                    controller,
                  ),

                  SizedBox(height: 24),

                  // Navigation
                  _buildNavigationSection(context, controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    QuestionPageController controller,
  ) {
    return AppBar(
      leading: const AppBackLeading(),
      title: Text(controller.title),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      elevation: 0,
    );
  }

  Widget _buildTimer(BuildContext context, QuestionPageController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 16,
          ),
          SizedBox(width: 8),
          Obx(
            () => Text(
              _formatTime(controller.timeRemaining.value),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Question question,
    int questionNumber,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Question $questionNumber',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 16),

            // Instruction if available
            if (question.instruction != null &&
                question.instruction!.trim().isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildInstructionContent(
                        context,
                        question.instruction!,
                        question.id,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Question content with LaTeX support
            _buildQuestionContent(context, question.content, question.id),

            // Image if available
            if (question.image != null && question.image!.isNotEmpty) ...[
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  question.image!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Image failed to load',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(
    BuildContext context,
    String content,
    int questionId,
  ) {
    if (LaTeXUtils.containsLaTeX(content)) {
      return TeXWidget(key: ValueKey('question_$questionId'), math: content);
    } else {
      return Text(content, style: TextStyle(fontSize: 12));
    }
  }

  Widget _buildInstructionContent(
    BuildContext context,
    String instruction,
    int questionId,
  ) {
    final theme = Theme.of(context);
    if (LaTeXUtils.containsLaTeX(instruction)) {
      return TeXWidget(
        key: ValueKey('instruction_$questionId'),
        math: instruction,
      );
    } else {
      return Text(
        instruction,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontSize: 12,
          height: 1.4,
        ),
      );
    }
  }

  Widget _buildChoicesSection(
    BuildContext context,
    List<Choice> choices,
    QuestionPageController controller,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your answer:',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            ...choices.asMap().entries.map((entry) {
              final index = entry.key;
              final choice = entry.value;
              final choiceLabel = String.fromCharCode(65 + index); // A, B, C, D

              return Obx(() {
                final isSelected =
                    controller.userAnswers[controller
                        .currentQuestionIndex
                        .value] ==
                    choice.id;
                final bool hasAnsweredCurrent =
                    controller.userAnswers[controller
                        .currentQuestionIndex
                        .value] !=
                    null;
                final currentQuestion =
                    controller.questions[controller.currentQuestionIndex.value];
                final correctChoiceId = currentQuestion.choices
                    .firstWhere((c) => c.isCorrect)
                    .id;
                // Determine visual state
                bool highlightAsCorrect = false;
                bool highlightAsIncorrect = false;
                if (controller.mode == QuestionMode.practice &&
                    hasAnsweredCurrent) {
                  if (choice.id == correctChoiceId) {
                    highlightAsCorrect = true;
                  }
                  if (isSelected && choice.id != correctChoiceId) {
                    highlightAsIncorrect = true;
                  }
                }
                if (controller.showAnswers.value) {
                  // Review mode after submission behaves like revealing answers
                  highlightAsCorrect = choice.id == correctChoiceId;
                  highlightAsIncorrect =
                      isSelected && choice.id != correctChoiceId;
                }

                return _buildChoiceItem(
                  context,
                  choice,
                  choiceLabel,
                  isSelected,
                  () => controller.selectAnswer(choice.id),
                  highlightAsCorrect: highlightAsCorrect,
                  highlightAsIncorrect: highlightAsIncorrect,
                );
              });
            }),

            // Immediate feedback text for Practice Mode and Review Mode
            Obx(() {
              if (controller.mode != QuestionMode.practice &&
                  !controller.showAnswers.value) {
                return SizedBox();
              }
              final answered =
                  controller.userAnswers[controller
                      .currentQuestionIndex
                      .value] !=
                  null;
              if (!answered) return SizedBox();
              final currentQuestion =
                  controller.questions[controller.currentQuestionIndex.value];
              final correctChoiceId = currentQuestion.choices
                  .firstWhere((c) => c.isCorrect)
                  .id;
              final selectedId = controller
                  .userAnswers[controller.currentQuestionIndex.value]!;
              final isCorrect = selectedId == correctChoiceId;
              return Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isCorrect ? 'Correct' : 'Incorrect',
                      style: TextStyle(
                        color: isCorrect
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceItem(
    BuildContext context,
    Choice choice,
    String label,
    bool isSelected,
    VoidCallback onTap, {
    bool highlightAsCorrect = false,
    bool highlightAsIncorrect = false,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlightAsCorrect
              ? theme.colorScheme.tertiaryContainer
              : highlightAsIncorrect
              ? theme.colorScheme.errorContainer
              : (isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surface),
          border: Border.all(
            color: highlightAsCorrect
                ? theme.colorScheme.tertiary
                : highlightAsIncorrect
                ? theme.colorScheme.error
                : (isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3)),
            width: (highlightAsCorrect || highlightAsIncorrect || isSelected)
                ? 2
                : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Choice label (A, B, C, D)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: highlightAsCorrect
                    ? theme.colorScheme.tertiary
                    : highlightAsIncorrect
                    ? theme.colorScheme.error
                    : (isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color:
                        (isSelected ||
                            highlightAsCorrect ||
                            highlightAsIncorrect)
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(width: 16),

            // Choice content
            Expanded(
              child: _buildChoiceContent(context, choice.content, choice.id),
            ),

            // Selection indicator
            if (isSelected) ...[
              SizedBox(width: 12),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: highlightAsIncorrect
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  highlightAsIncorrect ? Icons.close : Icons.check,
                  color: theme.colorScheme.onPrimary,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceContent(
    BuildContext context,
    String content,
    int choiceId,
  ) {
    if (LaTeXUtils.containsLaTeX(content)) {
      return TeXWidget(key: ValueKey('choice_$choiceId'), math: content);
    } else {
      return Text(content, style: TextStyle(fontSize: 12));
    }
  }

  Widget _buildSolutionSection(
    BuildContext context,
    Question question,
    QuestionPageController controller,
  ) {
    final theme = Theme.of(context);

    // Show solution in practice mode after user has attempted the question OR in review mode
    final hasAnswered =
        controller.userAnswers[controller.currentQuestionIndex.value] != null;
    final isPracticeMode = controller.mode == QuestionMode.practice;
    final isReviewMode = controller.showAnswers.value;

    // Show solution if:
    // 1. Practice mode and user has answered, OR
    // 2. Review mode (after exam completion)
    if ((!isPracticeMode && !isReviewMode) || (!hasAnswered && !isReviewMode)) {
      return SizedBox.shrink();
    }

    // Don't show solution if there's no explanation
    if (question.explanation == null || question.explanation!.trim().isEmpty) {
      // For testing purposes, show a placeholder solution
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Solution Button
            InkWell(
              onTap: controller.toggleSolution,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.onTertiaryContainer,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      isReviewMode ? 'View Explanation' : 'Solution',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Obx(
                      () => AnimatedRotation(
                        turns: controller.showSolution.value ? 0.5 : 0.0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Solution Content (Expandable)
            Obx(
              () => AnimatedCrossFade(
                duration: Duration(milliseconds: 300),
                crossFadeState: controller.showSolution.value
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.tertiary,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No Solution Available',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No explanation is available for this question yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Solution Button
          InkWell(
            onTap: controller.toggleSolution,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    isReviewMode ? 'View Explanation' : 'Solution',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Obx(
                    () => AnimatedRotation(
                      turns: controller.showSolution.value ? 0.5 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Solution Content (Expandable)
          Obx(
            () => AnimatedCrossFade(
              duration: Duration(milliseconds: 300),
              crossFadeState: controller.showSolution.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.tertiary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Explanation',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildSolutionContent(
                      context,
                      question.explanation!,
                      question.id,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionContent(
    BuildContext context,
    String explanation,
    int questionId,
  ) {
    if (LaTeXUtils.containsLaTeX(explanation)) {
      return TeXWidget(
        key: ValueKey('solution_$questionId'),
        math: explanation,
      );
    } else {
      return Text(
        explanation,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      );
    }
  }

  Widget _buildNavigationSection(
    BuildContext context,
    QuestionPageController controller,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Question progress indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Obx(
            () => Text(
              '${controller.currentQuestionIndex.value + 1} / ${controller.questions.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SizedBox(height: 16),

        // Navigation buttons
        Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.currentQuestionIndex.value > 0
                    ? controller.previousQuestion
                    : null,
                icon: Icon(Icons.arrow_back),
                label: Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(width: 16),

            // Next/Submit button
            Expanded(
              child: Obx(() {
                final isLastQuestion =
                    controller.currentQuestionIndex.value ==
                    controller.questions.length - 1;
                final canProceed = controller.canMoveToNext;
                final isSubmitting = controller.isSubmitting.value;

                return ElevatedButton.icon(
                  onPressed: canProceed && !isSubmitting
                      ? (isLastQuestion
                            ? controller.submitQuiz
                            : controller.nextQuestion)
                      : null,
                  icon: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          isLastQuestion ? Icons.check : Icons.arrow_forward,
                        ),
                  label: Text(
                    isSubmitting
                        ? 'Submitting...'
                        : (isLastQuestion ? 'Submit' : 'Next'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsPage(
    BuildContext context,
    QuestionPageController controller,
  ) {
    final theme = Theme.of(context);
    final correctAnswers = controller.calculateCorrectAnswers();
    final totalQuestions = controller.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).round();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Results Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Quiz Completed!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Score Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),

                    SizedBox(height: 16),

                    Text(
                      '$correctAnswers/$totalQuestions',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      '$percentage%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.reviewAnswers,
                      icon: Icon(Icons.quiz),
                      label: Text('Review Answers'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.finishQuiz,
                      icon: Icon(Icons.check),
                      label: Text('Finish'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionsState(
    BuildContext context,
    QuestionPageController controller,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, controller),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Empty state icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    size: 60,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),

                SizedBox(height: 32),

                // Empty state title
                Text(
                  'No Questions Available',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                // Empty state description
                Text(
                  'There are no questions available for this quiz at the moment. Please try again later or contact support if this problem persists.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                // Action buttons
                Column(
                  children: [
                    // Retry button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // You can add retry logic here if needed
                          Get.back();
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Contact support button (optional)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // You can add contact support logic here
                          // For now, just show a snackbar
                          Get.snackbar(
                            'Contact Support',
                            'Please contact our support team for assistance.',
                            backgroundColor: theme.colorScheme.primaryContainer,
                            colorText: theme.colorScheme.onPrimaryContainer,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: EdgeInsets.all(16),
                            borderRadius: 12,
                          );
                        },
                        icon: Icon(Icons.support_agent),
                        label: Text('Contact Support'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
