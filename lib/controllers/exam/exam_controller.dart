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

class ExamController extends GetxController {
  final ExamService _examService = ExamService();
  final HiveExamStorage _hiveExamStorage = HiveExamStorage();
  // Completion now handled within HiveExamStorage
  final InternetConnection _internetConnection = InternetConnection();
  bool _isLoading = true;
  bool get isLoading => _isLoading;
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
      }
    });

    _hiveExamStorage.listen((event) {
      _exams = event.where((e) => e.examType != 'quiz').toList();
      _refreshCompletionBadges();
      update();
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

  Future<void> loadExams() async {
    _isLoading = true;
    _error = null;
    update();

    final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');

    try {
      final grade = _user?.grade;
      final exams_ = await _examService.getAvailableExams(
        device.id,
        gradeId: grade?.id,
      );
      await _hiveExamStorage.setExams(exams_);
      _exams = (await _hiveExamStorage.getExams())
          .where((e) => e.examType != 'quiz')
          .toList();
    } catch (e) {
      _exams = (await _hiveExamStorage.getExams())
          .where((e) => e.examType != 'quiz')
          .toList();
      if (_exams.isEmpty) {
        _error = 'Failed to load exams. Please try again.';
        AppSnackbar.showError('Error', _error!);
      }
    } finally {
      _isLoading = false;
      await _refreshCompletionBadges();
      update();
    }
  }

  Future<void> _updateExamDownloadStatus() async {
    for (var exam in _exams) {
      final questions = await _hiveExamStorage.getQuestions(exam.id);
      exam.isDownloaded = questions.isNotEmpty;
    }
    update();
  }

  Future<void> _refreshCompletionBadges() async {
    _completedExamIds = await _hiveExamStorage.completedExamIds();
    update();
  }

  Future<void> refreshCompletionBadges() async {
    await _refreshCompletionBadges();
  }

  Future<void> selectSubject(int index) async {
    final subject = _subjects[index];
    _selectedSubjectIndex = index;
    final exams = await _hiveExamStorage.getExams();
    if (subject.id == 0) {
      _exams = exams.where((e) => e.examType != 'quiz').toList();
    } else {
      _exams = exams
          .where((e) => e.subject?.id == subject.id && e.examType != 'quiz')
          .toList();
    }
    // Update download status for filtered exams
    await _updateExamDownloadStatus();
  }

  void startExam(int examId) {
    // Navigate to exam detail page
    Get.to(
      () => ExamDetailPage(exam: _exams.firstWhere((e) => e.id == examId)),
    );
  }

  void navigateToExamDetail(int examId) {
    // Navigate to exam detail page
    Get.to(
      () => ExamDetailPage(exam: _exams.firstWhere((e) => e.id == examId)),
    );
  }

  Future<void> refreshExams() async {
    await loadExams();
  }

  Future<void> refreshExamDownloadStatus() async {
    await _updateExamDownloadStatus();
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
