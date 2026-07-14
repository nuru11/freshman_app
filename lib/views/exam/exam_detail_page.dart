import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vector_academy/controllers/exam/exam_controller.dart';
import 'package:vector_academy/controllers/exam/question_page_controller.dart';
import 'package:vector_academy/controllers/misc/downloads_controller.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/exam/exam_result_page.dart';
import 'package:vector_academy/views/exam/question_page.dart';

class ExamDetailPage extends StatefulWidget {
  final Exam exam;

  const ExamDetailPage({super.key, required this.exam});

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  late Exam _exam;
  final HiveExamStorage _examStorage = HiveExamStorage();
  final ExamService _examService = ExamService();
  DownloadsController? _downloadsController;
  ExamController? _examController;
  bool _isStarting = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _exam = widget.exam;
    _downloadsController = Get.isRegistered<DownloadsController>()
        ? Get.find<DownloadsController>()
        : Get.put(DownloadsController());
    if (Get.isRegistered<ExamController>()) {
      _examController = Get.find<ExamController>();
    }
  }

  bool get _isDownloaded => _exam.isDownloaded && _exam.questions.isNotEmpty;
  bool get _allowPractice {
    final modeType = (_exam.modeType).toLowerCase();
    return modeType == 'both' || modeType == 'practice';
  }

  bool get _allowExam {
    final modeType = (_exam.modeType).toLowerCase();
    return modeType == 'both' ||
        modeType == 'exam' ||
        modeType == 'exam_mode' ||
        modeType == 'exam mode';
  }

  ExamProgress? get _progress => _exam.progress;

  Future<void> _refreshExam() async {
    final exams = await _examStorage.getExams();
    for (final exam in exams) {
      if (exam.id == _exam.id) {
        setState(() {
          _exam = exam;
        });
        break;
      }
    }
    await _examController?.refreshExamDownloadStatus();
  }

  Future<void> _handleDownload() async {
    if (_downloadsController == null || _isDownloading) return;
    setState(() {
      _isDownloading = true;
    });
    try {
      await _downloadsController!.downloadExam(_exam);
      await _refreshExam();
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _handleStart() async {
    await _startExamFlow();
  }

  Future<void> _handleContinue() async {
    if (_progress == null) return;
    final mode = _progress!.mode == 'practice'
        ? QuestionMode.practice
        : QuestionMode.exam;
    await _startExamFlow(presetMode: mode, resume: true);
  }

  Future<void> _startExamFlow({
    QuestionMode? presetMode,
    bool resume = false,
  }) async {
    if (_exam.isLocked) {
      AppSnackbar.showInfo(
        'Locked Exam',
        'Please unlock this exam before starting.',
      );
      return;
    }

    if (!_isDownloaded) {
      await _handleDownload();
      if (!_isDownloaded) return;
    }

    final selectedMode = presetMode ?? await _pickMode();
    if (selectedMode == null) return;

    if (!mounted) return;
    setState(() {
      _isStarting = true;
    });

    try {
      final questions = await _resolveQuestionsForMode(
        selectedMode,
        resume: resume,
      );
      if (questions.isEmpty) {
        AppSnackbar.showInfo(
          'No Questions Available',
          'All questions for this exam have already been answered.',
        );
        return;
      }

      Get.to(
        () => QuestionPage(
          title: _exam.name,
          initialTimeMinutes: _exam.duration,
          questions: questions,
          onComplete: (answers, _) {
            final correctAnswers = _calculateCorrectAnswers(answers, questions);
            final score = questions.isEmpty
                ? 0
                : (correctAnswers / questions.length * 100).round();
            Get.to(
              () => ExamResultPage(
                score: score,
                correctAnswers: correctAnswers,
                totalQuestions: questions.length,
              ),
            );
          },
          allowReview: true,
          showTimer: true,
          mode: selectedMode,
          examId: _exam.id,
          examModeType: _exam.modeType,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<QuestionMode?> _pickMode() async {
    if (!_allowPractice && _allowExam) {
      return QuestionMode.exam;
    }
    if (_allowPractice && !_allowExam) {
      return QuestionMode.practice;
    }

    final result = await showDialog<QuestionMode>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'How would you like to proceed?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModeCard(
                accent: theme.colorScheme.primary,
                icon: Icons.school,
                title: 'Practice Mode',
                subtitle: 'Check answers immediately and learn as you go.',
                badgeText: _allowExam ? 'Learning focused' : null,
                enabled: _allowPractice,
                onTap: () => Navigator.of(context).pop(QuestionMode.practice),
              ),
              SizedBox(height: 12),
              _ModeCard(
                accent: theme.colorScheme.secondary,
                icon: Icons.fact_check,
                title: 'Exam Mode',
                subtitle: 'Simulate real exam conditions.',
                badgeText: _allowPractice ? 'Timed challenge' : null,
                enabled: _allowExam,
                onTap: () => Navigator.of(context).pop(QuestionMode.exam),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<List<Question>> _resolveQuestionsForMode(
    QuestionMode mode, {
    bool resume = false,
  }) async {
    List<Question> questionsToShow = _exam.questions;

    if (mode == QuestionMode.exam && !resume) {
      try {
        final user = await HiveUserStorage().getUser();
        if (user != null) {
          final device = await UserDevice.getDeviceInfo(user.phoneNumber);
          final allQuestions = await _examService.getQuestions(
            device.id,
            _exam.id,
          );
          final filtered = allQuestions
              .where((question) => !question.hasUserAnswered)
              .toList();

          if (filtered.isNotEmpty) {
            questionsToShow = filtered;
          } else {
            return [];
          }
        }
      } catch (e) {
        logger.e('Failed to reload questions for exam mode: $e');
      }
    }

    return questionsToShow;
  }

  Future<void> _confirmRestartAttempt() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Over?'),
        content: Text(
          'Your saved progress will be cleared so you can retake this exam from the beginning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Start Over'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return;

    await _examStorage.clearProgress(_exam.id, 'exam');
    await _examStorage.clearProgress(_exam.id, 'practice');
    await _examStorage.clearCompleted(_exam.id);
    _exam.progress = null;
    _exam.isCompleted = false;
    setState(() {});
    await _examController?.refreshCompletionBadges();
  }

  int _calculateCorrectAnswers(
    List<int> userAnswers,
    List<Question> questions,
  ) {
    int correct = 0;
    for (int i = 0; i < userAnswers.length && i < questions.length; i++) {
      final question = questions[i];
      final userAnswerId = userAnswers[i];
      final correctChoice = question.choices.firstWhere(
        (choice) => choice.isCorrect,
        orElse: () => question.choices.first,
      );
      if (userAnswerId == correctChoice.id) {
        correct++;
      }
    }
    return correct;
  }

  Future<void> _shareExam(BuildContext context) async {
    try {
      final shareLink = ShareUtils.generateExamLink(_exam.id);
      final shareText = '${_exam.name}\n\n$shareLink';

      await Share.share(shareText, subject: _exam.name);
    } catch (e) {
      logger.e('Error sharing exam: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share exam'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackLeading(),
        title: Text('Exam Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareExam(context),
            tooltip: 'Share exam',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshExam,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          children: [
            Text(
              _exam.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _exam.subject?.name ?? 'General',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            _buildHighlights(theme),
            SizedBox(height: 24),
            _buildStatusSection(theme),
            SizedBox(height: 24),
            _buildActionSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlights(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _HighlightTile(
            icon: Icons.schedule,
            label: 'Duration',
            value: '${_exam.duration} min',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _HighlightTile(
            icon: Icons.help_center,
            label: 'Questions',
            value:
                _exam.totalQuestions?.toString() ??
                (_exam.questions.isNotEmpty
                    ? '${_exam.questions.length}'
                    : 'Unknown'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: Icons.download_done,
                  label: _isDownloaded ? 'Downloaded' : 'Not downloaded',
                  color: _isDownloaded
                      ? Colors.green
                      : theme.colorScheme.secondary,
                ),
                if (_exam.year != null)
                  _StatusChip(
                    icon: Icons.calendar_month,
                    label: 'Year ${_exam.year}',
                    color: theme.colorScheme.primary,
                  ),
                if (_exam.isLocked)
                  _StatusChip(
                    icon: Icons.lock,
                    label: 'Locked',
                    color: Colors.orange,
                  ),
                if (_exam.isCompleted)
                  _StatusChip(
                    icon: Icons.emoji_events,
                    label: 'Completed',
                    color: Colors.green,
                  ),
                if (_progress != null)
                  _StatusChip(
                    icon: Icons.play_circle,
                    label:
                        'In progress (${_progress!.mode == 'practice' ? 'Practice' : 'Exam'})',
                    color: Colors.blueGrey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(ThemeData theme) {
    final isBusy = _isDownloading || _isStarting;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            if (_exam.isLocked)
              _DisabledBanner(
                message:
                    'This exam is currently locked. Please unlock it to continue.',
              )
            else if (!_isDownloaded)
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _handleDownload,
                icon: _isDownloading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.download),
                label: Text('Download Exam'),
              )
            else if (_progress != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: isBusy ? null : _handleContinue,
                    child: Text(
                      'Continue ${_progress!.mode == 'practice' ? 'Practice' : 'Exam'} Mode',
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: isBusy ? null : _handleStart,
                    child: Text('Start a New Attempt'),
                  ),
                  TextButton(
                    onPressed: isBusy ? null : _confirmRestartAttempt,
                    child: Text('Clear saved progress'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: isBusy ? null : _handleStart,
                icon: _isStarting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.play_arrow),
                label: Text('Start Exam'),
              ),
            SizedBox(height: 12),
            Text(
              _isDownloaded
                  ? 'Choose a mode to begin. Practice mode gives instant feedback, while Exam mode mirrors the official experience.'
                  : 'Download the exam to review details, attempt questions, and track your progress offline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HighlightTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (badgeText != null) ...[
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
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
    );
  }
}

class _DisabledBanner extends StatelessWidget {
  final String message;

  const _DisabledBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.orange[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
