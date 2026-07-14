import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/views.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final HiveExamStorage _examStorage = HiveExamStorage();
  final HiveUserStorage _userStorage = HiveUserStorage();
  final ExamService _examService = ExamService();

  /// Initialize deep link listening
  void initialize() {
    // Listen to incoming links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) {
        logger.e('Deep link error: $err');
      },
    );

    // Check for initial link (when app is opened from a deep link)
    _checkInitialLink();
  }

  /// Check for initial deep link when app starts
  Future<void> _checkInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      logger.e('Error getting initial link: $e');
    }
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    logger.i('Received deep link: $uri');

    try {
      final path = uri.path;
      final queryParams = uri.queryParameters;

      // Parse the path and navigate accordingly
      if (path.isEmpty || path == '/') {
        // Root path - navigate to home
        _navigateToRoute(VIEWS.home.path);
        return;
      }

      // Handle different deep link patterns
      switch (path) {
        case '/home':
          _navigateToRoute(VIEWS.home.path);
          break;

        case '/login':
          _navigateToRoute(VIEWS.login.path);
          break;

        case '/register':
          // Extract agent_id from query parameters if present
          logger.d('queryParams: $queryParams');
          if (queryParams.containsKey('agent_id')) {
            final agentId = int.tryParse(queryParams['agent_id'] ?? '');
            if (agentId != null) {
              Get.toNamed(
                VIEWS.register.path,
                arguments: {'agent_id': agentId},
              );
            } else {
              _navigateToRoute(VIEWS.register.path);
            }
          } else {
            _navigateToRoute(VIEWS.register.path);
          }
          break;

        case '/subjects':
          _navigateToRoute(VIEWS.subjects.path);
          break;

        case '/downloads':
          _navigateToRoute(VIEWS.downloads.path);
          break;

        case '/support':
          _navigateToRoute(VIEWS.support.path);
          break;

        case '/about':
          _navigateToRoute(VIEWS.about.path);
          break;

        case '/faq':
          _navigateToRoute(VIEWS.faq.path);
          break;

        case '/edit-profile':
          _navigateToRoute(VIEWS.editProfile.path);
          break;

        // Subject detail with ID
        case '/subject':
        case '/subject-detail':
          if (queryParams.containsKey('id')) {
            final subjectId = int.tryParse(queryParams['id'] ?? '');
            if (subjectId != null) {
              Get.toNamed(
                VIEWS.subjectDetail.path,
                arguments: {'subjectId': subjectId},
              );
            } else {
              _navigateToRoute(VIEWS.subjects.path);
            }
          } else {
            _navigateToRoute(VIEWS.subjects.path);
          }
          break;

        // Chapter detail with ID
        case '/chapter':
        case '/chapter-detail':
          if (queryParams.containsKey('id')) {
            final chapterId = int.tryParse(queryParams['id'] ?? '');
            if (chapterId != null) {
              Get.toNamed(
                VIEWS.chapterDetail.path,
                arguments: {'chapterId': chapterId},
              );
            } else {
              _navigateToRoute(VIEWS.subjects.path);
            }
          } else {
            _navigateToRoute(VIEWS.subjects.path);
          }
          break;

        // Exam detail with ID
        case '/exam':
        case '/exams':
          if (!await _handleExamDetailQuery(queryParams)) {
            _navigateToExamTab();
          }
          break;

        case '/exam-detail':
          if (!await _handleExamDetailQuery(queryParams)) {
            _navigateToExamTab();
          }
          break;

        // News detail with ID
        case '/news':
        case '/news-detail':
          logger.d('queryParams: $queryParams');
          if (queryParams.containsKey('id')) {
            final newsId = int.tryParse(queryParams['id'] ?? '');
            logger.d('newsId: $newsId');
            if (newsId != null) {
              final args = {'newsId': newsId};
              logger.d(
                'About to call Get.toNamed with path: ${VIEWS.newsDetail.path}, arguments: $args',
              );
              Get.toNamed(VIEWS.newsDetail.path, arguments: args);
              logger.d(
                'After Get.toNamed call, checking Get.arguments: ${Get.arguments}',
              );
            }
          }
          break;

        // Video player with parameters
        case '/video':
        case '/video-player':
          if (queryParams.containsKey('url') &&
              queryParams.containsKey('title') &&
              queryParams.containsKey('id')) {
            final videoUrl = queryParams['url'] ?? '';
            final videoTitle = queryParams['title'] ?? '';
            final videoId = int.tryParse(queryParams['id'] ?? '0') ?? 0;
            Get.toNamed(
              VIEWS.videoPlayer.path,
              arguments: {
                'videoUrl': videoUrl,
                'videoTitle': videoTitle,
                'videoId': videoId,
              },
            );
          }
          break;

        // PDF reader with parameters
        case '/pdf':
        case '/pdf-reader':
          if (queryParams.containsKey('url') &&
              queryParams.containsKey('title') &&
              queryParams.containsKey('id')) {
            final pdfUrl = queryParams['url'] ?? '';
            final pdfTitle = queryParams['title'] ?? '';
            final pdfId = int.tryParse(queryParams['id'] ?? '0') ?? 0;
            Get.toNamed(
              VIEWS.pdfReader.path,
              arguments: {
                'pdfUrl': pdfUrl,
                'pdfTitle': pdfTitle,
                'pdfId': pdfId,
              },
            );
          }
          break;

        default:
          // Try to match dynamic routes
          if (path.startsWith('/subject/')) {
            final parts = path.split('/');
            if (parts.length >= 3) {
              final subjectId = int.tryParse(parts[2]);
              if (subjectId != null) {
                Get.toNamed(
                  VIEWS.subjectDetail.path,
                  arguments: {'subjectId': subjectId},
                );
                return;
              }
            }
          } else if (path.startsWith('/chapter/')) {
            final parts = path.split('/');
            if (parts.length >= 3) {
              final chapterId = int.tryParse(parts[2]);
              if (chapterId != null) {
                Get.toNamed(
                  VIEWS.chapterDetail.path,
                  arguments: {'chapterId': chapterId},
                );
                return;
              }
            }
          } else if (path.startsWith('/exam/')) {
            final parts = path.split('/');
            if (parts.length >= 3) {
              final examId = int.tryParse(parts[2]);
              if (examId != null) {
                if (!await _handleExamDetailId(examId)) {
                  _navigateToExamTab();
                }
                return;
              }
            }
            _navigateToExamTab();
          } else if (path.startsWith('/exams/')) {
            final parts = path.split('/');
            if (parts.length >= 3) {
              final examId = int.tryParse(parts[2]);
              if (examId != null) {
                if (!await _handleExamDetailId(examId)) {
                  _navigateToExamTab();
                }
                return;
              }
            }
            _navigateToExamTab();
          } else if (path.startsWith('/news/')) {
            final parts = path.split('/');
            if (parts.length >= 3) {
              final newsId = int.tryParse(parts[2]);
              if (newsId != null) {
                Get.toNamed(
                  VIEWS.newsDetail.path,
                  arguments: {'newsId': newsId},
                );
                return;
              }
            }
          }

          // Default to home if route not found
          logger.w('Unknown deep link path: $path');
          _navigateToRoute(VIEWS.home.path);
      }
    } catch (e) {
      logger.e('Error handling deep link: $e');
      // Navigate to home on error
      _navigateToRoute(VIEWS.home.path);
    }
  }

  /// Navigate to a route
  void _navigateToRoute(String route) {
    // Check if user is logged in
    final authService = Get.find<AuthService>();
    if (authService.user.value == null && route != VIEWS.login.path) {
      // User not logged in, navigate to login first
      Get.offAllNamed(VIEWS.login.path);
    } else if (route == VIEWS.register.path) {
      Get.offAllNamed(route);
    } else {
      // User is logged in or navigating to login, proceed with navigation
      if (route == VIEWS.home.path) {
        Get.offAllNamed(route);
      } else {
        Get.toNamed(route);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }

  Future<bool> _handleExamDetailQuery(Map<String, String> queryParams) async {
    logger.d('queryParams: $queryParams');
    if (queryParams.containsKey('id')) {
      final examId = int.tryParse(queryParams['id'] ?? '');
      if (examId != null) {
        return _handleExamDetailId(examId);
      }
    }
    return false;
  }

  Future<bool> _handleExamDetailId(int examId) async {
    try {
      Exam? exam = await _getCachedExam(examId);
      exam ??= await _fetchExamFromServer(examId);

      if (exam != null) {
        _openExamDetail(exam);
        return true;
      }
    } catch (e) {
      logger.e('Failed to open exam detail for $examId: $e');
    }
    return false;
  }

  void _navigateToExamTab() {
    _navigateToRoute(VIEWS.home.path);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.isRegistered<MainNavigationController>()) {
        Get.find<MainNavigationController>().changeIndex(1);
      }
    });
  }

  Future<Exam?> _getCachedExam(int examId) async {
    final exams = await _examStorage.getExams();
    try {
      return exams.firstWhere((exam) => exam.id == examId);
    } catch (_) {
      return null;
    }
  }

  Future<Exam?> _fetchExamFromServer(int examId) async {
    final user = await _userStorage.getUser();
    if (user == null) return null;

    final device = await UserDevice.getDeviceInfo(user.phoneNumber);
    final exams = await _examService.getAvailableExams(
      device.id,
      gradeId: user.grade.id,
    );
    await _examStorage.setExams(exams);
    try {
      return exams.firstWhere((exam) => exam.id == examId);
    } catch (_) {
      return null;
    }
  }

  void _openExamDetail(Exam exam) {
    if (Get.currentRoute == VIEWS.examDetail.path) {
      Get.off(() => ExamDetailPage(exam: exam));
    } else {
      Get.to(() => ExamDetailPage(exam: exam));
    }
  }
}
