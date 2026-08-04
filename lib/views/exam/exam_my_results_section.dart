import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/freshman_page_scaffold.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';
import 'package:vector_academy/controllers/misc/user_score_controller.dart';
import 'package:vector_academy/models/models.dart';

/// Personal competition scores for the Exam tab — paper summary, no gradient hero.
class ExamMyResultsSection extends StatelessWidget {
  const ExamMyResultsSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserScoreController>()) {
      Get.put(UserScoreController());
    }

    return GetBuilder<UserScoreController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _CompetitionPicker(controller: controller),
            ),
            Expanded(child: _ResultsBody(controller: controller)),
          ],
        );
      },
    );
  }
}

class _CompetitionPicker extends StatelessWidget {
  const _CompetitionPicker({required this.controller});

  final UserScoreController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.isLoadingCompetitions && controller.competitions.isEmpty) {
      return FreshmanSurfaceCard(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading competitions…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.competitions.isEmpty) {
      return FreshmanSurfaceCard(
        child: Text(
          'No competitions available yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        ),
      );
    }

    return FreshmanSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: controller.selectedCompetitionId,
          isExpanded: true,
          hint: Text(
            'Choose a competition',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
          items: controller.competitions.map((competition) {
            final id = competition['id'] as int;
            final name =
                competition['name'] as String? ?? 'Unknown competition';
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: controller.selectCompetition,
        ),
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({required this.controller});

  final UserScoreController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackExams = controller.examFallbackScores;

    if (controller.selectedCompetitionId == null) {
      return const _EmptyMessage(
        icon: Icons.assessment_outlined,
        message: 'Select a competition to view your results',
      );
    }

    if (controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 12),
            Text(
              'Loading your results…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.error != null &&
        controller.userResult == null &&
        fallbackExams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: errorColor),
              const SizedBox(height: 12),
              Text(
                controller.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: controller.refreshResults,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.userResult == null) {
      if (controller.isLoadingExamFallback) {
        return Center(
          child: CircularProgressIndicator(color: primaryColor),
        );
      }
      if (fallbackExams.isNotEmpty) {
        return _FallbackList(exams: fallbackExams);
      }
      return const _EmptyMessage(
        icon: Icons.quiz_outlined,
        message: 'No scores found for this competition',
      );
    }

    final result = controller.userResult!;
    if (!result.hasUserAttempted) {
      if (fallbackExams.isNotEmpty) {
        return _FallbackList(exams: fallbackExams);
      }
      return const _EmptyMessage(
        icon: Icons.event_busy_outlined,
        message: "You haven't started this competition yet",
      );
    }

    final examsToShow =
        result.exams.isNotEmpty ? result.exams : fallbackExams;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: controller.refreshResults,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _SummaryCard(result: result),
          const SizedBox(height: 20),
          Text(
            'Exam breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 10),
          if (examsToShow.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: _EmptyMessage(
                icon: Icons.assignment_outlined,
                message: 'No exam scores available',
              ),
            )
          else
            ...examsToShow.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExamScoreRow(exam: e.value, index: e.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});

  final UserLeaderboardResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = result.totalQuestions > 0
        ? (result.totalScore / result.totalQuestions * 100).clamp(0.0, 100.0)
        : 0.0;

    return FreshmanSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.competetionName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.hasUserAttempted ? 'Attempted' : 'Not attempted',
            style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: 'Average',
                  value: '${percentage.toStringAsFixed(0)}%',
                  emphasize: true,
                ),
              ),
              Container(width: 1, height: 40, color: borderColor),
              Expanded(
                child: _StatBlock(
                  label: 'Exams',
                  value: '${result.exams.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: emphasize
              ? theme.textTheme.headlineMedium?.copyWith(color: primaryColor)
              : theme.textTheme.headlineSmall?.copyWith(color: onSurfaceColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ExamScoreRow extends StatelessWidget {
  const _ExamScoreRow({required this.exam, required this.index});

  final CompetetionExam exam;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = exam.totalQuestions > 0
        ? ((exam.score / exam.totalQuestions) * 100).clamp(0.0, 100.0)
        : exam.score.clamp(0.0, 100.0);

    return FreshmanSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Text(
            '${index + 1}.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.examName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exam.totalQuestions > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${exam.score.toStringAsFixed(0)} / ${exam.totalQuestions}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: secondaryVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackList extends StatelessWidget {
  const _FallbackList({required this.exams});

  final List<CompetetionExam> exams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => Get.find<UserScoreController>().refreshResults(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          FreshmanSurfaceCard(
            child: Text(
              'Showing exam-mode scores while competition stats are unavailable.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...exams.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ExamScoreRow(exam: e.value, index: e.key),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
