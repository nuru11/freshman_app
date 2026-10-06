import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/user_results.dart';
import 'package:vector_academy/services/api/leaderboard.dart';
import 'package:vector_academy/services/api/exams.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/utils.dart';

class UserScoreController extends GetxController {
  final UserResultsService _userResultsService = UserResultsService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  final ExamService _examService = ExamService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingCompetitions = false;
  bool get isLoadingCompetitions => _isLoadingCompetitions;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> get competitions => _competitions;

  int? _selectedCompetitionId;
  int? get selectedCompetitionId => _selectedCompetitionId;

  UserLeaderboardResult? _userResult;
  UserLeaderboardResult? get userResult => _userResult;
  List<CompetetionExam> _examFallbackScores = [];
  List<CompetetionExam> get examFallbackScores => _examFallbackScores;
  bool _isLoadingExamFallback = false;
  bool get isLoadingExamFallback => _isLoadingExamFallback;

  bool _reloadQueued = false;
  bool _scoresNeedServerRefresh = false;
  final List<CompetetionExam> _pendingLocalScores = [];

  User? _user;

  List<CompetetionExam> get visibleHomeExams {
    final result = _userResult;
    final base =
        result != null && result.hasUserAttempted && result.exams.isNotEmpty
        ? result.exams
        : _examFallbackScores;
    return _withPending(base);
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoadingCompetitions = true;
    _error = null;
    update(); // Notify UI of loading state

    try {
      _user = await HiveUserStorage().getUser();
      // Load competitions without blocking - don't auto-load user results
      await loadCompetitions();
      HiveUserStorage().listen((event) {
        _user = event;
        loadCompetitions();
      }, 'user');
    } catch (e) {
      logger.e('Failed to initialize UserScoreController: $e');
      _error = 'Failed to initialize. Please try again.';
      _isLoadingCompetitions = false;
      update(); // Notify UI of error state
    }
  }

  Future<void> loadCompetitions() async {
    // Prevent multiple simultaneous loads
    _isLoadingCompetitions = true;
    _error = null;
    _competitions = []; // Clear old competitions
    _selectedCompetitionId = null; // Reset selection
    _userResult = null; // Clear old results
    _examFallbackScores = List<CompetetionExam>.from(_pendingLocalScores);
    update(); // Notify UI immediately

    try {
      final phoneNumber = _user?.phoneNumber;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        logger.w('loadCompetitions: No phone number available');
        _competitions = [];
        _isLoadingCompetitions = false;
        update();
        return;
      }

      final device = await UserDevice.getDeviceInfo(phoneNumber);
      final competitions = await _leaderboardService.getAvailableCompetitions(
        device.id,
      );

      // Filter out competitions with invalid IDs
      _competitions = competitions.where((comp) {
        final id = comp['id'];
        return id != null && id is int;
      }).toList();

      logger.i('Loaded ${_competitions.length} competitions');

      if (_competitions.isNotEmpty) {
        final firstCompetitionId = _competitions.first['id'] as int?;
        if (firstCompetitionId != null) {
          _selectedCompetitionId = firstCompetitionId;
          await loadUserResult();
        }
      }
    } catch (e) {
      logger.e('Failed to load competitions: $e');
      _competitions = [];
      if (!_hasVisibleScores) {
        _error = 'Failed to load competitions. Please try again.';
      }
    } finally {
      _isLoadingCompetitions = false;
      update(); // Notify UI of completion
    }
  }

  void selectCompetition(int? competitionId) {
    if (_selectedCompetitionId == competitionId) {
      logger.i('selectCompetition: Already selected, skipping');
      return; // Already selected
    }

    // Validate competition ID exists in the list
    if (competitionId != null) {
      final exists = _competitions.any((comp) => comp['id'] == competitionId);
      if (!exists) {
        logger.w(
          'selectCompetition: Competition ID $competitionId not found in list',
        );
        return;
      }
    }

    logger.i('selectCompetition: Selecting competition $competitionId');
    _selectedCompetitionId = competitionId;
    _userResult = null; // Clear old results
    _examFallbackScores = List<CompetetionExam>.from(_pendingLocalScores);
    _error = null; // Clear old errors
    _isLoading = false; // Reset loading state
    update(); // Update UI immediately with new selection

    if (competitionId != null) {
      // Load results in background without blocking UI
      loadUserResult();
    }
  }

  Future<void> loadUserResult() async {
    if (_selectedCompetitionId == null) {
      logger.w('loadUserResult: No competition selected');
      return;
    }

    // A refresh requested while a load is in flight must still run afterward.
    if (_isLoading) {
      _reloadQueued = true;
      logger.w('loadUserResult: Already loading, will refresh again');
      return;
    }

    logger.i(
      'loadUserResult: Loading results for competition $_selectedCompetitionId',
    );
    _isLoading = true;
    _error = null;
    _userResult = null; // Clear old data
    _examFallbackScores = List<CompetetionExam>.from(_pendingLocalScores);
    update(); // Keep a just-finished score on screen while refreshing

    try {
      final result = await _userResultsService.getUserLeaderboardResult(
        _selectedCompetitionId!,
      );

      if (result == null) {
        logger.w('loadUserResult: No results found');
        _userResult = null;
        await _loadExamFallbackScores();
        _error = _examFallbackScores.isEmpty
            ? 'No results found for this competition'
            : null;
      } else {
        logger.i('loadUserResult: Successfully loaded results');
        if (result.exams.isNotEmpty) {
          _retainPending(result.exams);
        }
        _userResult = result;
        if (result.exams.isEmpty) {
          await _loadExamFallbackScores();
        }
        _error = null;
      }
    } catch (e) {
      logger.e('Failed to load user result: $e');
      if (!_hasVisibleScores) {
        _error = 'Failed to load results. Please try again.';
      }
      if (_userResult == null) {
        _examFallbackScores = _withPending(_examFallbackScores);
      }
    } finally {
      _isLoading = false;
      update(); // Notify UI of completion
      if (_reloadQueued) {
        _reloadQueued = false;
        await loadUserResult();
      }
    }
  }

  Future<void> refreshResults() async {
    await loadUserResult();
  }

  /// Shows a just-finished exam on Home immediately, then reloads server scores.
  void publishFinishedExamScore({
    required String examName,
    required int correctAnswers,
    required int totalQuestions,
  }) {
    final name = examName.trim();
    if (name.isEmpty || totalQuestions <= 0) {
      return;
    }

    final entry = CompetetionExam(
      examName: name,
      score: correctAnswers.toDouble(),
      totalQuestions: totalQuestions,
    );
    _pendingLocalScores.removeWhere((exam) => exam.examName == name);
    _pendingLocalScores.insert(0, entry);
    _examFallbackScores = _withPending(
      _examFallbackScores.where((exam) => exam.examName != name).toList(),
    );
    _scoresNeedServerRefresh = true;
    _error = null;
    update();
    refreshResults();
  }

  Future<void> refreshHomeScoresIfNeeded() async {
    if (!_scoresNeedServerRefresh) {
      return;
    }
    await refreshResults();
  }

  bool get _hasVisibleScores {
    final result = _userResult;
    if (result != null && result.hasUserAttempted && result.exams.isNotEmpty) {
      return true;
    }
    return _examFallbackScores.isNotEmpty || _pendingLocalScores.isNotEmpty;
  }

  Future<void> _loadExamFallbackScores() async {
    final userId = _user?.id;
    final phoneNumber = _user?.phoneNumber;
    if (userId == null || phoneNumber == null || phoneNumber.isEmpty) {
      _examFallbackScores = _withPending(const []);
      return;
    }

    _isLoadingExamFallback = true;
    update();

    try {
      final device = await UserDevice.getDeviceInfo(phoneNumber);
      final exams = await _examService.getAvailableExams(
        device.id,
        gradeId: _user!.grade.id,
      );
      final examModeExams = exams.where(_countsAsExamMode).take(20).toList();

      final fallbackScores = <CompetetionExam>[];
      for (final exam in examModeExams) {
        if (fallbackScores.length >= 10) {
          break;
        }

        try {
          final leaderboard = await _leaderboardService.getExamLeaderboard(
            device.id,
            exam.id,
          );
          final myEntry = leaderboard.firstWhereOrNull(
            (entry) => entry.userId == userId,
          );
          if (myEntry != null) {
            fallbackScores.add(
              CompetetionExam(
                examName: exam.name,
                score: myEntry.score,
                totalQuestions: 100,
              ),
            );
          }
        } catch (e) {
          logger.w('Fallback exam score fetch failed for exam ${exam.id}: $e');
        }
      }

      _retainPending(fallbackScores);
      _examFallbackScores = _withPending(fallbackScores);
    } catch (e) {
      logger.e('Failed to load fallback exam scores: $e');
      _examFallbackScores = _withPending(_examFallbackScores);
    } finally {
      _isLoadingExamFallback = false;
      update();
    }
  }

  List<CompetetionExam> _withPending(List<CompetetionExam> scores) {
    if (_pendingLocalScores.isEmpty) {
      return scores;
    }

    final names = scores.map((exam) => exam.examName).toSet();
    final missing = _pendingLocalScores
        .where((exam) => !names.contains(exam.examName))
        .toList();
    if (missing.isEmpty) {
      return scores;
    }
    return [...missing, ...scores];
  }

  void _retainPending(List<CompetetionExam> serverExams) {
    if (serverExams.isEmpty || _pendingLocalScores.isEmpty) {
      return;
    }

    final names = serverExams.map((exam) => exam.examName).toSet();
    _pendingLocalScores.removeWhere((exam) => names.contains(exam.examName));
    _scoresNeedServerRefresh = _pendingLocalScores.isNotEmpty;
  }

  bool _countsAsExamMode(Exam exam) {
    final mode = exam.modeType.toLowerCase();
    return mode == 'exam_mode' ||
        mode == 'exam' ||
        mode == 'exam mode' ||
        mode == 'both';
  }
}
