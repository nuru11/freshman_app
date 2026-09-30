import 'package:get/get.dart';
import 'package:vector_academy/controllers/leaderboard/leaderboard_controller.dart';
import 'package:vector_academy/controllers/misc/user_score_controller.dart';
import 'package:vector_academy/views/exam/exam_detail_page.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/utils.dart';

/// Exam tab body sections: list, competition standings, personal results.
enum ExamSection { exams, standings, myResults }

class ExamBrowseGroup {
  final int? id;
  final String name;
  final int sortOrder;
  final int count;

  const ExamBrowseGroup({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.count,
  });
}

class ExamController extends GetxController {
  static const uncategorizedCategoryName = 'Uncategorized';
  static const generalSectionName = 'General';
  final ExamService _examService = ExamService();
  final HiveExamStorage _hiveExamStorage = HiveExamStorage();
  // Completion now handled within HiveExamStorage
  final InternetConnection _internetConnection = InternetConnection();
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isOffline = false;
  bool get isOffline => _isOffline;
  User? _user;
  bool get hasFullAccessOverride =>
      hasFullAccessOverrideForPhone(_user?.phoneNumber);
  final Subject _allPlaceholderSubject = Subject(
    id: 0,
    name: 'All',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  List<Exam> _exams = [];
  List<Exam> get exams => _exams;
  Set<int> _completedExamIds = {};
  Set<int> get completedExamIds => _completedExamIds;

  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;

  int _selectedSubjectIndex = 0;
  int get selectedSubjectIndex => _selectedSubjectIndex;

  ExamSection _examSection = ExamSection.exams;
  ExamSection get examSection => _examSection;
  int get examSectionIndex => _examSection.index;

  String? _error;
  String? get error => _error;

  void selectExamSection(ExamSection section) {
    if (_examSection == section) return;

    if (section != ExamSection.exams && !requireAuth()) {
      return;
    }

    if (section == ExamSection.standings) {
      _ensureLeaderboardController();
    } else if (section == ExamSection.myResults) {
      _ensureUserScoreController();
    }

    _examSection = section;
    update();
  }

  void selectExamSectionIndex(int index) {
    if (index < 0 || index >= ExamSection.values.length) return;
    selectExamSection(ExamSection.values[index]);
  }

  LeaderboardController _ensureLeaderboardController() {
    final controller = Get.isRegistered<LeaderboardController>()
        ? Get.find<LeaderboardController>()
        : Get.put(LeaderboardController());

    if (controller.selectedType != LeaderboardType.competition) {
      controller.setLeaderboardType(LeaderboardType.competition);
      controller.loadCompetitions();
    } else if (controller.competitions.isEmpty &&
        !controller.isLoadingCompetitions) {
      controller.loadCompetitions();
    }

    return controller;
  }

  UserScoreController _ensureUserScoreController() {
    return Get.isRegistered<UserScoreController>()
        ? Get.find<UserScoreController>()
        : Get.put(UserScoreController());
  }

  @override
  void onInit() async {
    super.onInit();
    _user = await HiveUserStorage().getUser();
    loadExams();
    loadSubjects();
    _completedExamIds = await _hiveExamStorage.completedExamIds();

    HiveUserStorage().listen((event) {
      _user = event;
      loadExams();
    }, 'user');

    _internetConnection.onStatusChange.listen((event) {
      if (event == InternetStatus.connected) {
        loadExams();
      } else {
        _applyOfflineFilter();
      }
    });

    _hiveExamStorage.listen((_) {
      _syncVisibleExams();
    }, 'exams');

    HiveSubjectsStorage().listen((event) {
      _subjects = [_allPlaceholderSubject, ...event];
      update();
    }, 'subjects');
  }

  Future<void> loadSubjects() async {
    final subjects = await HiveSubjectsStorage().read('subjects');
    _subjects = [_allPlaceholderSubject, ...subjects];
    update();
  }

  Future<void> _applyOfflineFilter() async {
    _isOffline = true;
    _exams = await _visibleExams();
    update();
  }

  Future<void> _syncVisibleExams() async {
    _exams = await _visibleExams();
    await _refreshCompletionBadges();
  }

  Future<List<Exam>> _visibleExams() async {
    final exams = await _hiveExamStorage.getExams();
    for (final exam in exams) {
      exam.isDownloaded = exam.questions.isNotEmpty;
    }

    return exams.where((exam) {
      if (!_isExamScreenExam(exam)) return false;
      if (_isOffline && !hasDownloadedExamContent(exam)) return false;
      return true;
    }).toList();
  }

  Future<void> loadExams() async {
    _isLoading = true;
    _error = null;
    update();

    _isOffline = !await _internetConnection.hasInternetAccess;

    try {
      if (!_isOffline) {
        final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
        final grade = _user?.grade;
        final exams_ = await _examService.getAvailableExams(
          device.id,
          gradeId: grade?.id,
        );
        await _hiveExamStorage.setExams(exams_);
      }
      _exams = await _visibleExams();
    } catch (e) {
      _exams = await _visibleExams();
      if (!_isOffline && _exams.isEmpty) {
        _error = 'Failed to load exams. Please try again.';
        AppSnackbar.showError('Error', _error!);
      }
    } finally {
      _isLoading = false;
      await _refreshCompletionBadges();
      update();
    }
  }

  Future<void> _refreshCompletionBadges() async {
    _completedExamIds = await _hiveExamStorage.completedExamIds();
    update();
  }

  Future<void> refreshCompletionBadges() async {
    await _refreshCompletionBadges();
  }

  Future<void> selectSubject(int index) async {
    _selectedSubjectIndex = index;
    update();
  }

  bool _isExamScreenExam(Exam exam) {
    if (exam.examType == 'quiz') return false;
    final mode = exam.modeType.toLowerCase();
    return mode == 'practice' || mode == 'exam_mode' || mode == 'both';
  }

  int get _selectedSubjectId {
    if (_subjects.isEmpty ||
        _selectedSubjectIndex < 0 ||
        _selectedSubjectIndex >= _subjects.length) {
      return 0;
    }
    return _subjects[_selectedSubjectIndex].id;
  }

  List<ExamBrowseGroup> get categoryGroups => _groupsFor(null);

  List<ExamBrowseGroup> sectionsForCategory({int? categoryId}) {
    return _groupsFor(categoryId, sections: true);
  }

  List<ExamBrowseGroup> _groupsFor(int? categoryId, {bool sections = false}) {
    final groups = <String, ExamBrowseGroup>{};
    final counts = <String, int>{};
    for (final exam in _exams) {
      if (sections) {
        final matchesCategory = categoryId == null
            ? exam.examCategory == null
            : exam.examCategory?.id == categoryId;
        if (!matchesCategory) continue;
      }
      final grouping = sections ? exam.section : exam.examCategory;
      final fallbackName = sections
          ? generalSectionName
          : uncategorizedCategoryName;
      final key = grouping == null
          ? fallbackName
          : '${sections ? 's' : 'c'}-${grouping.id}';
      counts[key] = (counts[key] ?? 0) + 1;
      groups[key] = ExamBrowseGroup(
        id: grouping?.id,
        name: grouping?.name ?? fallbackName,
        sortOrder: grouping?.sortOrder ?? 1 << 20,
        count: counts[key]!,
      );
    }
    final list = groups.values.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  List<Exam> examsInSection({int? categoryId, int? sectionId}) {
    final subjectId = _selectedSubjectId;
    return _exams.where((exam) {
      final matchesCategory = categoryId == null
          ? exam.examCategory == null
          : exam.examCategory?.id == categoryId;
      if (!matchesCategory) return false;
      final matchesSection = sectionId == null
          ? exam.section == null
          : exam.section?.id == sectionId;
      if (!matchesSection) return false;
      if (subjectId != 0 && exam.subject?.id != subjectId) return false;
      return true;
    }).toList();
  }

  void startExam(int examId) {
    if (!requireAuth()) return;
    Get.to(
      () => ExamDetailPage(exam: _exams.firstWhere((e) => e.id == examId)),
    );
  }

  void navigateToExamDetail(int examId) {
    if (!requireAuth()) return;
    Get.to(
      () => ExamDetailPage(exam: _exams.firstWhere((e) => e.id == examId)),
    );
  }

  Future<void> refreshExams() async {
    await loadExams();
  }

  Future<void> refreshExamDownloadStatus() async {
    _exams = await _visibleExams();
    update();
  }

  Future<List<Exam>> searchExams(String query) async {
    return _exams
        .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  bool isExamLocked(Exam exam) {
    if (hasFullAccessOverride) {
      return false;
    }
    if (hasDownloadedExamContent(exam)) {
      return false;
    }
    return exam.isLocked;
  }
}
