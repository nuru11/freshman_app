import 'dart:async';
import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/leaderboard.dart';
import 'package:vector_academy/services/api/exams.dart';
import 'package:vector_academy/services/api/success_stories.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/utils.dart';

enum LeaderboardType { competition, exam }

class LeaderboardController extends GetxController {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final ExamService _examService = ExamService();
  final SuccessStoriesService _successStoriesService = SuccessStoriesService();
  final HiveLeaderboardCacheStorage _cacheStorage = HiveLeaderboardCacheStorage();
  final HiveExamStorage _examStorage = HiveExamStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool _isLoadingCompetitions = false;
  bool _isLoadingExams = false;

  String? _error;
  String? get error => _error;
  bool _isShowingOfflineData = false;
  bool get isShowingOfflineData => _isShowingOfflineData;

  LeaderboardType _selectedType = LeaderboardType.competition;
  LeaderboardType get selectedType => _selectedType;
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  List<LeaderboardEntry> _leaderboardEntries = [];
  List<LeaderboardEntry> get leaderboardEntries => _leaderboardEntries;
  List<SuccessStory> _successStories = [];
  List<SuccessStory> get successStories => _successStories;

  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> get competitions => _competitions;

  List<Exam> _exams = [];
  List<Exam> get exams => _exams;

  int? _selectedCompetitionId;
  int? get selectedCompetitionId => _selectedCompetitionId;

  int? _selectedExamId;
  int? get selectedExamId => _selectedExamId;

  User? _user;

  int get tabIndex => _selectedTabIndex;
  bool get isLoadingCompetitions => _isLoadingCompetitions;
  bool get isLoadingExams => _isLoadingExams;

  @override
  void onInit() async {
    super.onInit();
    _user = await HiveUserStorage().getUser();
    await loadSuccessStories();
    await loadCompetitions();
    await loadExams();
    HiveUserStorage().listen((event) {
      _user = event;
      loadCompetitions();
      loadExams();
    }, 'user');
  }

  Future<void> loadSuccessStories() async {
    try {
      final stories = await _successStoriesService.getSuccessStories();
      _successStories = stories.take(3).toList();
    } catch (e) {
      logger.w('Failed to load success stories preview: $e');
      _successStories = [];
    } finally {
      update();
    }
  }

  LeaderboardEntry? get myScoreEntry {
    final userId = _user?.id;
    if (userId == null) {
      return null;
    }
    return _leaderboardEntries.firstWhereOrNull((entry) => entry.userId == userId);
  }

  void onTabChanged(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
    }

    // First two tabs are leaderboard data sources.
    if (index == 0) {
      if (_selectedType != LeaderboardType.competition) {
        setLeaderboardType(LeaderboardType.competition);
      } else {
        update();
      }
      return;
    }

    if (index == 1) {
      if (_selectedType != LeaderboardType.exam) {
        setLeaderboardType(LeaderboardType.exam);
      } else {
        update();
      }
      return;
    }

    // My Score / Success Story tabs are informational views.
    update();
  }

  bool _isAutoSelecting = false;

  Future<void> loadCompetitions() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingCompetitions) {
      logger.w('loadCompetitions: Already loading, skipping');
      return;
    }

    _isLoadingCompetitions = true;
    update();

    try {
      final cachedCompetitions = await _cacheStorage.getCompetitions();
      if (cachedCompetitions.isNotEmpty) {
        _competitions = cachedCompetitions;
        update();
      }

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final competitions = await _leaderboardService.getAvailableCompetitions(
        device.id,
      );

      // Filter out competitions with invalid IDs
      _competitions = competitions.where((comp) {
        final id = comp['id'];
        return id != null && id is int;
      }).toList();
      await _cacheStorage.setCompetitions(_competitions);

      logger.i('Loaded ${_competitions.length} competitions');

      // Auto-select first competition if none selected and competitions available
      // Only do this once to prevent loops
      if (!_isAutoSelecting &&
          _selectedCompetitionId == null &&
          _competitions.isNotEmpty &&
          _selectedType == LeaderboardType.competition) {
        _isAutoSelecting = true;
        try {
          final firstId = _competitions.first['id'] as int;
          _selectedCompetitionId = firstId;
          await loadLeaderboard();
        } catch (e) {
          logger.e('Failed to auto-select competition: $e');
        } finally {
          _isAutoSelecting = false;
        }
      }

    } catch (e) {
      logger.e('Failed to load competitions: $e');
      final cachedCompetitions = await _cacheStorage.getCompetitions();
      _competitions = cachedCompetitions;
      _isAutoSelecting = false;
    } finally {
      _isLoadingCompetitions = false;
      update();
    }
  }

  Future<void> loadExams() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingExams) {
      logger.w('loadExams: Already loading, skipping');
      return;
    }

    _isLoadingExams = true;
    update();

    try {
      // Use the same source/filtering behavior as the Exams screen.
      final cachedExams = await _examStorage.getExams();
      if (cachedExams.isNotEmpty) {
        _exams = cachedExams.where((e) => e.examType != 'quiz').toList();
        update();
      }

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final grade = _user?.grade;
      final fetchedExams = await _examService.getAvailableExams(
        device.id,
        gradeId: grade?.id,
      );
      await _examStorage.setExams(fetchedExams);
      _exams = fetchedExams.where((e) => e.examType != 'quiz').toList();
      await _cacheStorage.setExams(_exams);

      logger.i('Loaded ${_exams.length} exams');

      // Auto-select first exam if none selected and exams available
      // Only do this once to prevent loops
      if (!_isAutoSelecting &&
          _selectedExamId == null &&
          _exams.isNotEmpty &&
          _selectedType == LeaderboardType.exam) {
        _isAutoSelecting = true;
        try {
          _selectedExamId = _exams.first.id;
          await loadLeaderboard();
        } catch (e) {
          logger.e('Failed to auto-select exam: $e');
        } finally {
          _isAutoSelecting = false;
        }
      }

    } catch (e) {
      logger.e('Failed to load exams: $e');
      final cachedExams = await _examStorage.getExams();
      _exams = cachedExams.where((e) => e.examType != 'quiz').toList();
      _isAutoSelecting = false;
    } finally {
      _isLoadingExams = false;
      update();
    }
  }

  void setLeaderboardType(LeaderboardType type) {
    if (_selectedType == type) return; // No change needed

    _selectedType = type;
    _selectedTabIndex = type == LeaderboardType.competition ? 0 : 1;
    _selectedCompetitionId = null;
    _selectedExamId = null;
    _leaderboardEntries = [];
    _error = null;
    _isAutoSelecting = false; // Reset flag to allow auto-selection for new type
    update();
  }

  void selectCompetition(int? competitionId) {
    if (_selectedCompetitionId == competitionId) {
      return; // Already selected
    }

    // Validate competition ID exists in the list
    if (competitionId != null) {
      final exists = _competitions.any((comp) => comp['id'] == competitionId);
      if (!exists) {
        logger.w('selectCompetition: Competition ID $competitionId not found in list');
        return;
      }
    }

    _selectedCompetitionId = competitionId;
    _selectedExamId = null;
    _leaderboardEntries = [];
    _error = null;
    update();
    if (competitionId != null) {
      loadLeaderboard();
    }
  }

  void selectExam(int? examId) {
    if (_selectedExamId == examId) {
      return; // Already selected
    }

    // Validate exam ID exists in the list
    if (examId != null) {
      final exists = _exams.any((exam) => exam.id == examId);
      if (!exists) {
        logger.w('selectExam: Exam ID $examId not found in list');
        return;
      }
    }

    _selectedExamId = examId;
    _selectedCompetitionId = null;
    _leaderboardEntries = [];
    _error = null;
    update();
    if (examId != null) {
      loadLeaderboard();
    }
  }

  Future<void> loadLeaderboard() async {
    if (_selectedType == LeaderboardType.competition &&
        _selectedCompetitionId == null) {
      return;
    }
    if (_selectedType == LeaderboardType.exam && _selectedExamId == null) {
      return;
    }

    // Prevent multiple simultaneous loads
    if (_isLoading || _isRefreshing) {
      logger.w('loadLeaderboard: Already loading, skipping');
      return;
    }

    _isLoading = true;
    _error = null;
    _isShowingOfflineData = false;
    update();

    try {
      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');

      if (_selectedType == LeaderboardType.competition) {
        _leaderboardEntries = await _leaderboardService
            .getCompetitionLeaderboard(device.id, _selectedCompetitionId!);
        await _cacheStorage.setLeaderboardEntries(
          type: 'competition',
          sourceId: _selectedCompetitionId!,
          entries: _leaderboardEntries,
        );
      } else {
        _leaderboardEntries = await _leaderboardService.getExamLeaderboard(
          device.id,
          _selectedExamId!,
        );
        await _cacheStorage.setLeaderboardEntries(
          type: 'exam',
          sourceId: _selectedExamId!,
          entries: _leaderboardEntries,
        );
      }
    } catch (e) {
      logger.e('Failed to load leaderboard: $e');
      final cacheType = _selectedType == LeaderboardType.competition
          ? 'competition'
          : 'exam';
      final cacheSourceId = _selectedType == LeaderboardType.competition
          ? _selectedCompetitionId
          : _selectedExamId;

      if (cacheSourceId != null) {
        final cachedEntries = await _cacheStorage.getLeaderboardEntries(
          type: cacheType,
          sourceId: cacheSourceId,
        );
        if (cachedEntries.isNotEmpty) {
          _leaderboardEntries = cachedEntries;
          _error = null;
          _isShowingOfflineData = true;
        } else {
          _error = e.toString();
          _leaderboardEntries = [];
        }
      } else {
        _error = e.toString();
        _leaderboardEntries = [];
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      update();
    }
  }

  Future<void> refreshLeaderboard() async {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshing || _isLoading) {
      logger.w('refresh: Already refreshing/loading, skipping');
      return;
    }

    _isRefreshing = true;
    try {
      await loadLeaderboard();
    } finally {
      // loadLeaderboard will reset _isRefreshing, but ensure it's reset here too
      if (_isRefreshing) {
        _isRefreshing = false;
      }
    }
  }
}
