import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/controllers/subject/subject_detail_controller.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/controllers/misc/downloads_controller.dart';
import 'dart:io';

class ChapterDetailController extends GetxController {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isVideosLoading = false;
  bool get isVideosLoading => _isVideosLoading;

  bool _isNotesLoading = false;
  bool get isNotesLoading => _isNotesLoading;
  bool _isQuizzesLoading = true;
  bool get isQuizzesLoading => _isQuizzesLoading;

  String _chapterTitle = '';
  String get chapterTitle => _chapterTitle;

  Chapter? _chapter;
  Chapter? get chapter => _chapter;
  bool _isSubjectLocked = true;
  bool get isSubjectLocked => _isSubjectLocked;
  bool _isPreviewChapterAccess = false;
  bool get isPreviewChapterAccess => _isPreviewChapterAccess;

  List<Video> _videos = [];
  List<Video> get videos => _videos;

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  List<Exam> _quizzes = [];
  List<Exam> get quizzes => _quizzes;

  final _downloadsController = Get.find<DownloadsController>();

  int chapterId = 0;
  int subjectId = 0;

  RxMap<int, dynamic> videoDownloadProgress = RxMap<int, dynamic>({});
  RxMap<int, dynamic> noteDownloadProgress = RxMap<int, dynamic>({});
  RxMap<int, dynamic> quizDownloadProgress = RxMap<int, dynamic>({});

  final HiveVideoStorage _hiveVideoStorage = HiveVideoStorage();
  final HiveNoteStorage _hiveNoteStorage = HiveNoteStorage();
  final ExamService _examService = ExamService();
  final HiveExamStorage _examStorage = HiveExamStorage();
  final VideoApiService _videoApiService = VideoApiService();
  final NoteService _noteApiService = NoteService();
  User? _user;
  bool get _hasFullAccessOverride =>
      hasFullAccessOverrideForPhone(_user?.phoneNumber);

  bool isVideoLocked(Video video) {
    if (_hasFullAccessOverride || _isPreviewChapterAccess) {
      return false;
    }
    if (hasDownloadedVideoFile(video)) {
      return false;
    }
    return video.isLocked;
  }

  bool isQuizLocked(Exam quiz) {
    if (_hasFullAccessOverride || _isPreviewChapterAccess) {
      return false;
    }
    if (hasDownloadedExamContent(quiz)) {
      return false;
    }
    return quiz.isLocked;
  }

  bool isNoteLocked(Note note) {
    if (_hasFullAccessOverride || _isPreviewChapterAccess) {
      return false;
    }
    if (hasDownloadedNoteFile(note)) {
      return false;
    }
    return note.isLocked;
  }

  void _showLockedContentMessage() {
    Get.snackbar(
      'Locked Content',
      'Subscribe to this subject to access all chapters.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  @override
  void onInit() async {
    chapterId = Get.arguments?['chapterId'] ?? 1;
    subjectId = Get.arguments?['subjectId'] ?? 1;
    _user = await HiveUserStorage().getUser();

    final canAccessChapter = await _canAccessCurrentChapter();
    if (!canAccessChapter) {
      Get.offNamed(
        VIEWS.payments.path,
        arguments: {'subjectId': subjectId},
      );
      Get.snackbar(
        'Subscription Required',
        'Subscribe to unlock all chapters for this subject.',
        snackPosition: SnackPosition.BOTTOM,
      );
      super.onInit();
      return;
    }

    _registerDownloadCallbacks();
    await loadChapterDetail();
    await Future.wait([
      loadVideos(),
      loadNotes(),
      loadQuizzes(),
    ]);
    HiveUserStorage().listen((event) {
      _user = event;
      loadChapterDetail().then((_) {
        Future.wait([
          loadVideos(),
          loadNotes(),
          loadQuizzes(),
        ]);
      });
    }, 'user');
    super.onInit();
  }

  Future<bool> _canAccessCurrentChapter() async {
    if (_hasFullAccessOverride) {
      return true;
    }
    try {
      final subjects = await HiveSubjectsStorage().read('subjects');
      final subject = subjects.firstWhereOrNull((s) => s.id == subjectId);
      if (subject == null) {
        return true;
      }
      if (!subject.isLocked) {
        return true;
      }
      final chapters = [...subject.chapters]
        ..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
      if (chapters.isEmpty) {
        return true;
      }
      final freePreviewChapterId = chapters.first.id;
      return chapterId == freePreviewChapterId;
    } catch (e) {
      logger.e('Failed to validate chapter access: $e');
      return true;
    }
  }

  @override
  void onClose() {
    _clearDownloadCallbacks();
    super.onClose();
  }

  /// Push live progress/completion events from the permanent DownloadsController
  /// into this controller's model objects so the UI stays in sync.
  void _registerDownloadCallbacks() {
    _downloadsController.onVideoProgress = (videoId, progress) {
      final v = _videos.firstWhereOrNull((v) => v.id == videoId);
      if (v != null) {
        v.isDownloading = true;
        v.downloadProgress = progress;
        update();
      }
    };
    _downloadsController.onVideoCompleted = (videoId, filePath) {
      final v = _videos.firstWhereOrNull((v) => v.id == videoId);
      if (v != null) {
        v.filePath = filePath;
        v.isDownloaded = true;
        v.isDownloading = false;
        v.downloadProgress = 1.0;
        update();
      }
    };
    _downloadsController.onVideoError = (videoId) {
      final v = _videos.firstWhereOrNull((v) => v.id == videoId);
      if (v != null) {
        v.isDownloading = false;
        v.downloadProgress = 0.0;
        update();
      }
    };
    _downloadsController.onNoteProgress = (noteId, progress) {
      final n = _notes.firstWhereOrNull((n) => n.id == noteId);
      if (n != null) {
        n.isDownloading = true;
        n.downloadProgress = progress;
        noteDownloadProgress[noteId] = {
          'progress': progress,
          'isDownloading': true,
        };
        update();
      }
    };
    _downloadsController.onNoteCompleted = (noteId, filePath) {
      final n = _notes.firstWhereOrNull((n) => n.id == noteId);
      if (n != null) {
        n.filePath = filePath;
        n.isDownloaded = true;
        n.isDownloading = false;
        n.downloadProgress = 1.0;
        noteDownloadProgress[noteId] = {
          'progress': 1.0,
          'isDownloading': false,
        };
        update();
      }
    };
    _downloadsController.onNoteError = (noteId) {
      final n = _notes.firstWhereOrNull((n) => n.id == noteId);
      if (n != null) {
        n.isDownloading = false;
        n.downloadProgress = 0.0;
        noteDownloadProgress.remove(noteId);
        update();
      }
    };
  }

  void _clearDownloadCallbacks() {
    _downloadsController.onVideoProgress = null;
    _downloadsController.onVideoCompleted = null;
    _downloadsController.onVideoError = null;
    _downloadsController.onNoteProgress = null;
    _downloadsController.onNoteCompleted = null;
    _downloadsController.onNoteError = null;
  }

  /// Restores in-progress download state when navigating back to this page.
  void _syncActiveDownloads() {
    for (final v in _videos) {
      final progress = _downloadsController.activeVideoDownloads[v.id];
      if (progress != null) {
        v.isDownloading = true;
        v.downloadProgress = progress;
      }
    }
    for (final n in _notes) {
      final progress = _downloadsController.activeNoteDownloads[n.id];
      if (progress != null) {
        n.isDownloading = true;
        n.downloadProgress = progress;
        noteDownloadProgress[n.id] = {
          'progress': progress,
          'isDownloading': true,
        };
      }
    }
  }

  Future<void> loadVideos() async {
    final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
    _isVideosLoading = true;
    update();
    try {
      final videos_ = await _videoApiService.getVideos(
        chapterId,
        deviceId: device.id,
      );

      _hiveVideoStorage.setVideos(chapterId, videos_);
      _videos = await _hiveVideoStorage.getVideos(chapterId);
      if (_isPreviewChapterAccess && _videos.any((v) => v.isLocked)) {
        logger.w(
          'Preview chapter contains locked videos. Backend should unlock chapter 1.',
        );
      }
    } catch (e) {
      logger.e('Error loading videos: $e');
      _videos = await _hiveVideoStorage.getVideos(chapterId);
    }
    _syncActiveDownloads();
    _isVideosLoading = false;
    update();
  }

  Future<void> loadNotes() async {
    final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
    _isNotesLoading = true;
    update();
    try {
      final notes_ = await _noteApiService.getNotes(
        device.id,
        chapterId: chapterId,
      );
      _hiveNoteStorage.setNotes(chapterId, notes_);
      _notes = await _hiveNoteStorage.getNotes(chapterId);
      if (_isPreviewChapterAccess && _notes.any((n) => n.isLocked)) {
        logger.w(
          'Preview chapter contains locked notes. Backend should unlock chapter 1.',
        );
      }
    } catch (e) {
      logger.e('Error loading notes: $e');
      _notes = await _hiveNoteStorage.getNotes(chapterId);
    }
    _syncActiveDownloads();
    _isNotesLoading = false;
    update();
  }

  Future<void> loadQuizzes() async {
    final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
    _isQuizzesLoading = true;
    update();
    try {
      final quizzes_ = await _examService.getAvailableExams(
        device.id,
        chapterId: chapterId,
        examType: "quiz",
      );
      logger.i('Setting quizzes for chapter $chapterId');
      logger.d(await _examStorage.getQuizzes(chapterId));
      _examStorage.setQuizzes(chapterId, quizzes_);
      _quizzes = await _examStorage.getQuizzes(chapterId);
      if (_isPreviewChapterAccess && _quizzes.any((q) => q.isLocked)) {
        logger.w(
          'Preview chapter contains locked quizzes. Backend should unlock chapter 1.',
        );
      }
    } catch (e) {
      _quizzes = await _examStorage.getQuizzes(chapterId);
    }
    _isQuizzesLoading = false;
    update();
  }

  Future<void> loadChapterDetail() async {
    _isLoading = true;
    update();

    try {
      Subject? subject;
      try {
        final subjects = await HiveSubjectsStorage().read('subjects');
        subject = subjects.firstWhereOrNull((s) => s.id == subjectId);
      } catch (e) {
        logger.w('Could not read subject from hive for chapter detail: $e');
      }

      // fallback via active subject detail controller
      if (subject == null) {
        try {
          final subjectController = Get.find<SubjectDetailController>();
          subject = subjectController.subject;
        } catch (e) {
          logger.w('SubjectDetailController not found, using fallback data');
        }
      }

      _isSubjectLocked = (subject?.isLocked ?? true) && !_hasFullAccessOverride;
      _chapter = subject?.chapters.firstWhereOrNull((ch) => ch.id == chapterId);
      _isPreviewChapterAccess = _hasFullAccessOverride ||
          (_isSubjectLocked && ((_chapter?.chapterNumber ?? 0) == 1));

      if (_chapter != null) {
        _chapterTitle = _chapter!.name;
        _videos = _chapter!.videos.map((e) => Video.fromJson(e)).toList();
        _notes = _chapter!.notes.map((e) => Note.fromJson(e)).toList();
        _quizzes = _chapter!.quizzes.map((e) => Exam.fromJson(e)).toList();
      }
    } catch (e) {
      logger.e('Error loading chapter details: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  void playVideo(int videoId) async {
    try {
      final video = _videos.firstWhereOrNull((v) => v.id == videoId);
      logger.d(video?.toJson());

      if (video != null) {
        if (isVideoLocked(video)) {
          _showLockedContentMessage();
          return;
        }
        // Check if video is downloaded
        if (!video.isDownloaded ||
            video.filePath == null ||
            video.filePath!.isEmpty) {
          Get.snackbar(
            'Video Not Available',
            'This video needs to be downloaded first to watch offline',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return;
        }

        // Check if the file actually exists
        final file = File(video.filePath!);
        if (!await file.exists()) {
          Get.snackbar(
            'File Not Found',
            'The downloaded video file could not be found. Please download again.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          // Reset download status
          video.isDownloaded = false;
          video.filePath = null;
          update();
          return;
        }

        // Use local file path for downloaded videos
        logger.d('Playing video from: ${video.filePath}');

        if (video.filePath != null) {
          logger.f('Playing video from: ${video.filePath}');
          Get.to(
            VideoPlayerScreen(
              videoId: video.id,
              videoUrl: video.filePath!, // Use local file path
              videoTitle: video.title,
            ),
          );
        }
      } else {
        Get.snackbar('Error', 'Video not found');
      }
    } catch (e) {
      logger.e('Error playing video: $e');
      Get.snackbar('Error', 'Failed to play video: $e');
    }
  }

  void openPDF(int noteId) {
    try {
      final note = _notes.firstWhereOrNull((n) => n.id == noteId);
      if (note != null) {
        if (isNoteLocked(note)) {
          _showLockedContentMessage();
          return;
        }
        String pdfUrl;

        // If note is downloaded, use local file path
        if (note.isDownloaded &&
            note.filePath != null &&
            note.filePath!.isNotEmpty) {
          final file = File(note.filePath!);
          if (file.existsSync()) {
            pdfUrl = note.filePath!;
            logger.d('Using local file path: $pdfUrl');
          } else {
            // File doesn't exist anymore, reset download status
            note.isDownloaded = false;
            note.filePath = null;
            update();
            Get.snackbar(
              'File Not Found',
              'The downloaded file could not be found. Please download again.',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            return;
          }
        } else {
          // For remote files, we need to get the actual URL from the API
          // The note.content field just contains "pdf", not the URL
          logger.e(
            'Remote PDF access not properly implemented. Note content: ${note.content}',
          );
          Get.snackbar(
            'Error',
            'Remote PDF viewing is not implemented. Please download the PDF first.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }

        logger.d(
          'Opening PDF with URL: $pdfUrl, Title: ${note.title}, ID: $noteId',
        );
        Get.to(
          PDFReaderScreen(pdfUrl: pdfUrl, pdfTitle: note.title, pdfId: noteId),
        );
      } else {
        Get.snackbar('Error', 'PDF not found');
      }
    } catch (e) {
      logger.e('Error opening PDF: $e');
      Get.snackbar('Error', 'Failed to open PDF');
    }
  }

  void downloadNote(int noteId) async {
    final note = _notes.firstWhereOrNull((n) => n.id == noteId);
    if (note == null) {
      Get.snackbar('Error', 'Note not found');
      return;
    }
    if (isNoteLocked(note)) {
      _showLockedContentMessage();
      return;
    }

    // If already downloaded open it directly
    if (note.isDownloaded &&
        note.filePath != null &&
        note.filePath!.isNotEmpty) {
      if (note.content.toLowerCase() == 'pdf') {
        openPDF(noteId);
      } else {
        Get.snackbar('Info', 'Note is already downloaded and available offline');
      }
      return;
    }

    // Delegate to the permanent DownloadsController so the download continues
    // even after this page is popped.
    await _downloadsController.downloadNote(note);
  }

  void startQuiz(Exam quiz) {
    if (isQuizLocked(quiz)) {
      _showLockedContentMessage();
      return;
    }
    _downloadsController.startExam(quiz);
  }

  void downloadQuiz(int quizId) async {
    try {
      final quiz = _quizzes.firstWhereOrNull((q) => q.id == quizId);
      if (quiz != null) {
        // Check if locked
        if (isQuizLocked(quiz)) {
          _showLockedContentMessage();
          return;
        }

        // Check if already downloaded
        if (quiz.isDownloaded && quiz.questions.isNotEmpty) {
          Get.snackbar(
            'Info',
            'Quiz is already downloaded',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
          return;
        }

        // Check if already downloading
        if (quiz.isLoadingQuestion) {
          Get.snackbar(
            'Already Downloading',
            'This quiz is already being downloaded',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }

        // Start download process
        quiz.isLoadingQuestion = true;
        quizDownloadProgress[quizId] = {'progress': 0.0, 'isDownloading': true};
        update();

        Get.snackbar(
          'Downloading',
          'Starting download of ${quiz.name}...',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
        final questions = await _examService.getQuestions(device.id, quiz.id);

        quiz.questions = questions;
        quiz.isDownloaded = true;
        quiz.isLoadingQuestion = false;

        // Update progress map
        quizDownloadProgress[quizId] = {
          'progress': 1.0,
          'isDownloading': false,
        };

        update();

        await _examStorage.setQuestions(quiz.id, questions);

        Get.snackbar(
          'Download Complete',
          'Quiz downloaded successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar('Error', 'Quiz not found');
      }
    } catch (e) {
      final quiz = _quizzes.firstWhereOrNull((q) => q.id == quizId);
      if (quiz != null) {
        quiz.isLoadingQuestion = false;
        quizDownloadProgress.remove(quizId);
        update();
      }

      logger.e('Error downloading quiz: $e');
      Get.snackbar(
        'Download Failed',
        'Failed to download quiz: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void downloadVideo(int videoId) async {
    final video = _videos.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) {
      Get.snackbar('Error', 'Video not found');
      return;
    }
    if (isVideoLocked(video)) {
      _showLockedContentMessage();
      return;
    }

    // Delegate to the permanent DownloadsController so the download continues
    // even after this page is popped.
    await _downloadsController.downloadVideo(video);
  }

}
