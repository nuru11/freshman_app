import 'package:vector_academy/utils/storages/storages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/controllers/home/main_navigation_controller.dart';
import 'package:vector_academy/controllers/misc/notifications_controller.dart';
import 'package:vector_academy/controllers/exam/exam_controller.dart';
import 'package:vector_academy/controllers/misc/downloads_controller.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/storages/app_header.dart';
import 'package:vector_academy/services/api/app_header_text.dart';
import 'dart:async';

enum FeaturedUpdateType { news, exam }

class FeaturedUpdateItem {
  final int id;
  final String title;
  final DateTime createdAt;
  final FeaturedUpdateType type;
  final String? subjectName;

  const FeaturedUpdateItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.type,
    this.subjectName,
  });
}

class HomeDashboardController extends GetxController {
  final TextEditingController homeSearchController = TextEditingController();
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  int _notificationCount = 3;
  int get notificationCount => _notificationCount;

  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;
  AppHeaderText? _appHeader;
  AppHeaderText? get appHeader => _appHeader;
  bool _isFeaturedUpdatesLoading = false;
  bool get isFeaturedUpdatesLoading => _isFeaturedUpdatesLoading;
  List<FeaturedUpdateItem> _featuredUpdates = [];
  List<FeaturedUpdateItem> get featuredUpdates => _featuredUpdates;
  Timer? _featuredUpdatesRefreshTimer;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  List<Chapter> _chapterResults = [];
  List<Chapter> get chapterResults => _chapterResults;
  List<Exam> _examResults = [];
  List<Exam> get examResults => _examResults;
  List<Video> _videoResults = [];
  List<Video> get videoResults => _videoResults;
  List<Note> _worksheetResults = [];
  List<Note> get worksheetResults => _worksheetResults;
  final Map<int, Subject> _subjectById = {};
  final Map<int, Chapter> _chapterById = {};

  User? get user => _user;
  User? _user;

  @override
  void onInit() async {
    super.onInit();

    _user = await HiveUserStorage().getUser();
    loadSubjects();
    loadAppHeader();
    loadFeaturedUpdates();
    _startFeaturedUpdatesAutoRefresh();

    InternetConnection().onStatusChange.listen((event) {
      logger.i('Internet status changed: $event');
      if (event == InternetStatus.connected) {
        loadSubjects();
        loadAppHeader();
        loadFeaturedUpdates(showLoader: false);
      }
    });
    HiveAppHeaderStorage().listen((event) {
      _appHeader = event;
      update();
    }, 'current_header_text');

    HiveUserStorage().listen((event) {
      _user = event;
      loadSubjects();
      loadAppHeader();
      loadFeaturedUpdates();
      update();
    }, 'user');
  }

  @override
  void onClose() {
    _featuredUpdatesRefreshTimer?.cancel();
    homeSearchController.dispose();
    super.onClose();
  }

  void _startFeaturedUpdatesAutoRefresh() {
    _featuredUpdatesRefreshTimer?.cancel();
    _featuredUpdatesRefreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => loadFeaturedUpdates(showLoader: false),
    );
  }

  void loadAppHeader() async {
    _appHeader = await HiveAppHeaderStorage().getCurrentHeaderText();
    update();
    try {
      final gradeId = _user?.grade.id;
      final appHeaderTexts = await AppHeaderTextService().getAppHeaderTexts(
        gradeId ?? 0,
      );
      _appHeader = appHeaderTexts.first;
      await HiveAppHeaderStorage().setCurrentHeaderText(_appHeader!);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> loadSubjects() async {
    _isLoading = true;
    update();
    try {
      logger.i('Loading subjects from api');
      final gradeId = _user?.grade.id;
      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');

      _subjects = await SubjectsService().getSubjects(
        device.id,
        gradeId: gradeId ?? 0,
      );
      await HiveSubjectsStorage().write('subjects', _subjects);
    } catch (e) {
      logger.i('Loading subjects from storage');
      logger.e(e);
      _subjects = await HiveSubjectsStorage().read('subjects');
    } finally {
      _isLoading = false;
      _rebuildLookups();
      _runUnifiedSearch();
      update();
    }
  }

  Future<void> loadFeaturedUpdates({bool showLoader = true}) async {
    if (showLoader) {
      _isFeaturedUpdatesLoading = true;
      update();
    }

    try {
      final gradeId = _user?.grade.id;
      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final responses = await Future.wait<dynamic>([
        NewsService().getNews(),
        ExamService().getAvailableExams(
          device.id,
          gradeId: gradeId,
          excludeExamType: 'quiz',
        ),
      ]);

      final latestNews = (responses[0] as List<News>)
          .map(
            (news) => FeaturedUpdateItem(
              id: news.id,
              title: news.title,
              createdAt: news.createdAt,
              type: FeaturedUpdateType.news,
            ),
          )
          .toList();

      final latestExams = (responses[1] as List<Exam>)
          .where((exam) => exam.examType != 'quiz')
          .map(
            (exam) => FeaturedUpdateItem(
              id: exam.id,
              title: exam.name,
              createdAt: exam.createdAt,
              type: FeaturedUpdateType.exam,
              subjectName: exam.subject?.name,
            ),
          )
          .toList();

      final merged = <FeaturedUpdateItem>[...latestNews, ...latestExams]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _featuredUpdates = merged.take(5).toList();
    } catch (e) {
      logger.e('Failed to load featured updates: $e');
    } finally {
      _isFeaturedUpdatesLoading = false;
      update();
    }
  }

  Future<void> refreshData() async {
    loadAppHeader();
    await Future.wait([
      loadSubjects(),
      loadFeaturedUpdates(showLoader: false),
    ]);
    Get.snackbar(
      'Refreshed',
      'Dashboard data updated successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openNotifications() {
    Get.to(() => NotificationsPage());
  }

  void startLearning() {
    // Navigate to subjects page (index 1 in bottom navigation)
    Get.find<MainNavigationController>().changeIndex(1);
  }

  void viewAllExams() {
    // Navigate to exam page (index 2 in bottom navigation)
    Get.find<MainNavigationController>().changeIndex(2);
  }

  void openExam(int examId) {
    final examController = Get.find<ExamController>();
    Exam? selectedExam;
    for (final exam in examController.exams) {
      if (exam.id == examId) {
        selectedExam = exam;
        break;
      }
    }

    if (selectedExam == null) {
      Get.find<MainNavigationController>().changeIndex(1);
      Get.snackbar(
        'Exam Updated',
        'Refresh exams to view the latest exam details.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(() => ExamDetailPage(exam: selectedExam!));
  }

  void openNews(int newsId) {
    Get.to(() => NewsDetailPage(newsId: newsId));
  }

  void openFeaturedUpdate(FeaturedUpdateItem item) {
    if (item.type == FeaturedUpdateType.exam) {
      openExam(item.id);
      return;
    }
    openNews(item.id);
  }

  void selectSubject(int subjectId) {
    // Navigate to subject page for the selected grade
    Get.to(() => SubjectDetail(), arguments: {'subjectId': subjectId});
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _runUnifiedSearch();
    update();
  }

  void clearSearch() {
    _searchQuery = '';
    homeSearchController.clear();
    _chapterResults = [];
    _examResults = [];
    _videoResults = [];
    _worksheetResults = [];
    update();
  }

  bool get hasSearchQuery => _searchQuery.isNotEmpty;
  bool get hasAnySearchResult =>
      _chapterResults.isNotEmpty ||
      _examResults.isNotEmpty ||
      _videoResults.isNotEmpty ||
      _worksheetResults.isNotEmpty;

  void openChapterSearchResult(Chapter chapter) {
    Get.toNamed(
      VIEWS.chapterDetail.path,
      arguments: {'chapterId': chapter.id, 'subjectId': chapter.subject},
    );
  }

  void openVideoSearchResult(Video video) {
    final subjectId = _resolveSubjectIdForChapter(video.chapter) ?? video.subject;
    Get.toNamed(
      VIEWS.chapterDetail.path,
      arguments: {'chapterId': video.chapter, 'subjectId': subjectId},
    );
  }

  void openWorksheetSearchResult(Note note) {
    final chapterId = note.chapter;
    if (chapterId == null) {
      Get.toNamed(VIEWS.downloads.path);
      return;
    }
    final subjectId = _resolveSubjectIdForChapter(chapterId);
    if (subjectId == null) {
      Get.toNamed(VIEWS.downloads.path);
      return;
    }
    Get.toNamed(
      VIEWS.chapterDetail.path,
      arguments: {'chapterId': chapterId, 'subjectId': subjectId},
    );
  }

  String getSubjectNameForChapter(int chapterId) {
    final chapter = _chapterById[chapterId];
    if (chapter == null) {
      return '';
    }
    return _subjectById[chapter.subject]?.name ?? '';
  }

  String getChapterNameById(int chapterId) {
    return _chapterById[chapterId]?.name ?? '';
  }

  void _rebuildLookups() {
    _subjectById.clear();
    _chapterById.clear();
    for (final subject in _subjects) {
      _subjectById[subject.id] = subject;
      for (final chapter in subject.chapters) {
        _chapterById[chapter.id] = chapter;
      }
    }
  }

  int? _resolveSubjectIdForChapter(int chapterId) {
    return _chapterById[chapterId]?.subject;
  }

  List<T> _rankAndLimit<T>({
    required List<T> items,
    required String normalizedQuery,
    required String Function(T item) primaryText,
    int limit = 10,
  }) {
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final startsWithMatches = <T>[];
    final containsMatches = <T>[];

    for (final item in items) {
      final text = primaryText(item).toLowerCase();
      if (text.startsWith(normalizedQuery)) {
        startsWithMatches.add(item);
      } else {
        containsMatches.add(item);
      }
    }

    return [...startsWithMatches, ...containsMatches].take(limit).toList();
  }

  bool _containsAny(String query, List<String?> values) {
    for (final value in values) {
      if ((value ?? '').toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }

  void _runUnifiedSearch() {
    final normalizedQuery = _searchQuery.toLowerCase();
    if (normalizedQuery.isEmpty) {
      _chapterResults = [];
      _examResults = [];
      _videoResults = [];
      _worksheetResults = [];
      return;
    }

    _rebuildLookups();

    final allChapters = _subjects
        .expand((subject) => subject.chapters)
        .where(
          (chapter) => _containsAny(normalizedQuery, [
            chapter.name,
            chapter.description,
            'chapter ${chapter.chapterNumber}',
            _subjectById[chapter.subject]?.name,
          ]),
        )
        .toList();

    final allExams = Get.isRegistered<ExamController>()
        ? Get.find<ExamController>().exams
        : <Exam>[];
    final matchingExams = allExams
        .where(
          (exam) => _containsAny(normalizedQuery, [
            exam.name,
            exam.examType,
            exam.subject?.name,
            exam.year,
            exam.modeType,
          ]),
        )
        .toList();

    final allVideos = Get.isRegistered<DownloadsController>()
        ? Get.find<DownloadsController>().allVideos
        : <Video>[];
    final matchingVideos = allVideos
        .where(
          (video) => _containsAny(normalizedQuery, [
            video.title,
            video.description,
            getChapterNameById(video.chapter),
            getSubjectNameForChapter(video.chapter),
          ]),
        )
        .toList();

    final allWorksheets = Get.isRegistered<DownloadsController>()
        ? Get.find<DownloadsController>().allNotes
        : <Note>[];
    final matchingWorksheets = allWorksheets
        .where(
          (note) => _containsAny(normalizedQuery, [
            note.title,
            note.content,
            note.chapter != null ? getChapterNameById(note.chapter!) : '',
            note.chapter != null ? getSubjectNameForChapter(note.chapter!) : '',
          ]),
        )
        .toList();

    _chapterResults = _rankAndLimit<Chapter>(
      items: allChapters,
      normalizedQuery: normalizedQuery,
      primaryText: (chapter) => chapter.name,
    );
    _examResults = _rankAndLimit<Exam>(
      items: matchingExams,
      normalizedQuery: normalizedQuery,
      primaryText: (exam) => exam.name,
    );
    _videoResults = _rankAndLimit<Video>(
      items: matchingVideos,
      normalizedQuery: normalizedQuery,
      primaryText: (video) => video.title,
    );
    _worksheetResults = _rankAndLimit<Note>(
      items: matchingWorksheets,
      normalizedQuery: normalizedQuery,
      primaryText: (worksheet) => worksheet.title,
    );
  }

  void updateNotificationCount() {
    // Recalculate notification count from notifications controller
    try {
      final notificationsController = Get.find<NotificationsController>();
      _notificationCount = notificationsController.notifications
          .where((n) => !n.isRead)
          .length;
      update();
    } catch (e) {
      // Notifications controller not found, ignore
    }
  }
}
