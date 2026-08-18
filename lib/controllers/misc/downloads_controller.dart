import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'dart:io';
import 'package:vector_academy/views/common/video_player_screen.dart';
import 'package:vector_academy/views/common/pdf_reader_screen.dart';
import 'package:vector_academy/views/exam/exam_detail_page.dart';
import 'package:vector_academy/controllers/exam/exam_controller.dart';

class DownloadsController extends GetxController {
  // API Services
  final VideoApiService _videoApiService = VideoApiService();
  final NoteService _noteApiService = NoteService();
  final ExamService _examApiService = ExamService();
  // Storage services
  final HiveVideoStorage _videoStorage = HiveVideoStorage();
  final HiveNoteStorage _noteStorage = HiveNoteStorage();
  final HiveExamStorage _examStorage = HiveExamStorage();

  // Observable lists for all content (both downloaded and available)
  List<Video> allVideos = <Video>[];
  List<Exam> allExams = <Exam>[];
  List<Note> allNotes = <Note>[];

  // Loading states
  bool isLoadingVideos = false;
  bool isLoadingExams = false;
  bool isLoadingNotes = false;

  // Tracks active download progress by ID so it survives page navigation
  final Map<int, double> activeVideoDownloads = {};
  final Map<int, double> pausedVideoDownloads = {};
  final Map<int, CancelToken> _videoCancelTokens = {};
  final Map<int, Video> _activeVideoSources = {};
  final Map<int, double> activeNoteDownloads = {};

  // Callbacks set by ChapterDetailController so progress can be pushed back
  // without creating a circular import.
  void Function(int videoId, double progress)? onVideoProgress;
  void Function(int videoId, String filePath)? onVideoCompleted;
  void Function(int videoId)? onVideoError;
  void Function(int videoId, double progress)? onVideoPaused;
  void Function(int noteId, double progress)? onNoteProgress;
  void Function(int noteId, String filePath)? onNoteCompleted;
  void Function(int noteId)? onNoteError;

  User? _user;

  bool get hasFullAccessOverride =>
      hasFullAccessOverrideForPhone(_user?.phoneNumber);

  bool isVideoLocked(Video video) {
    // App Store review: treat content as free (uncomment block to restore)
    return false;
    // if (hasFullAccessOverride) {
    //   return false;
    // }
    // if (hasDownloadedVideoFile(video)) {
    //   return false;
    // }
    // return video.isLocked;
  }

  bool isNoteLocked(Note note) {
    // App Store review: treat content as free (uncomment block to restore)
    return false;
    // if (hasFullAccessOverride) {
    //   return false;
    // }
    // if (hasDownloadedNoteFile(note)) {
    //   return false;
    // }
    // return note.isLocked;
  }

  bool isExamLocked(Exam exam) {
    // App Store review: treat content as free (uncomment block to restore)
    return false;
    // if (hasFullAccessOverride) {
    //   return false;
    // }
    // if (hasDownloadedExamContent(exam)) {
    //   return false;
    // }
    // return exam.isLocked;
  }

  @override
  void onInit() async {
    super.onInit();
    _user = await HiveUserStorage().getUser();
    loadAllVideos();
    HiveUserStorage().listen((event) {
      _user = event;
      loadAllVideos();
      loadAllExams();
      loadAllNotes();
    }, 'user');
    loadAllExams();
    loadAllNotes();
  }

  // Load all videos with download states
  Future<void> loadAllVideos() async {
    try {
      isLoadingVideos = true;
      update();

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final grade = _user?.grade;
      // This is a simplified approach - you might need to modify based on your API structure
      try {
        // Get videos from multiple chapters or subjects
        final videos = await _videoApiService.getAllVideos(
          gradeId: grade?.id ?? 0,
          deviceId: device.id,
        );
        _videoStorage.setAllVideos(videos);
      } catch (e) {
        logger.e('Error loading videos from chapter: $e');
      }

      allVideos = await _videoStorage.getAllVideos();
    } catch (e) {
      allVideos = await _videoStorage.getAllVideos();
    } finally {
      await _restorePausedVideoDownloads();
      isLoadingVideos = false;
      update();
    }
  }

  // Load all exams with download states
  Future<void> loadAllExams() async {
    try {
      isLoadingExams = true;
      update();

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');

      final grade = _user?.grade;

      // Get all available exams
      final exams = await _examApiService.getAvailableExams(
        device.id,
        gradeId: grade?.id,
      );

      await _examStorage.setExams(exams);

      allExams = await _examStorage.getExams();
    } catch (e) {
      allExams = await _examStorage.getExams();
    } finally {
      isLoadingExams = false;
      update();
    }
  }

  // Load all notes with download states
  Future<void> loadAllNotes() async {
    final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');

    try {
      isLoadingNotes = true;
      update();
      final grade = _user?.grade;

      List<Note> notes_ = await _noteApiService.getAllNotes(
        device.id,
        gradeId: grade?.id,
      );
      await _noteStorage.setAllNotes(notes_);

      allNotes = await _noteStorage.getAllNotes();
    } catch (e) {
      allNotes = await _noteStorage.getAllNotes();
    } finally {
      isLoadingNotes = false;
      update();
    }
  }

  // Download video
  Future<void> downloadVideo(Video video) async {
    if (video.isDownloaded) {
      AppSnackbar.showInfo('Info', 'Video is already downloaded');
      return;
    }

    if (video.isDownloading || activeVideoDownloads.containsKey(video.id)) {
      AppSnackbar.showInfo('Info', 'Video is already being downloaded');
      return;
    }

    try {
      video.isDownloading = true;
      video.isPaused = false;
      pausedVideoDownloads.remove(video.id);
      activeVideoDownloads[video.id] = video.downloadProgress;
      await _videoStorage.removePausedDownload(video.id);

      final token = CancelToken();
      _videoCancelTokens[video.id] = token;
      _activeVideoSources[video.id] = video;

      _mirrorVideoState(video);
      update();
      onVideoProgress?.call(video.id, video.downloadProgress);

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final partFile = await VideoApiService.partFileFor(video.id);
      final startByte = await partFile.exists() ? await partFile.length() : 0;

      await _videoApiService.downloadVideo(
        video.id,
        deviceId: device.id,
        cancelToken: token,
        startByte: startByte,
        onData: (data, progress) {
          if (data == null) return;
          if (!activeVideoDownloads.containsKey(video.id)) return;
          final p = (progress / 100.0).clamp(0.0, 1.0);
          video.downloadProgress = p;
          video.isDownloading = true;
          video.isPaused = false;
          activeVideoDownloads[video.id] = p;

          _mirrorVideoState(video);
          onVideoProgress?.call(video.id, p);
          update();
        },
        onDone: (path) {
          video.filePath = path;
          video.isDownloaded = true;
          video.isDownloading = false;
          video.isPaused = false;
          video.downloadProgress = 1.0;
          activeVideoDownloads.remove(video.id);
          pausedVideoDownloads.remove(video.id);
          _videoCancelTokens.remove(video.id);
          _activeVideoSources.remove(video.id);

          _mirrorVideoState(video);
          _videoStorage.addDownloadedVideo(video.id, path);
          _videoStorage.removePausedDownload(video.id);
          onVideoCompleted?.call(video.id, path);
          update();

          AppSnackbar.showSuccess('Success', 'Video downloaded successfully');
        },
        onError: (error) {
          _handleVideoDownloadFailure(video, error);
        },
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return;
      }
      await _handleVideoDownloadFailure(video, e);
    } catch (e) {
      await _handleVideoDownloadFailure(video, e);
    }
  }

  Future<void> pauseVideoDownload(int videoId) async {
    final token = _videoCancelTokens.remove(videoId);
    if (token == null || token.isCancelled) {
      return;
    }

    token.cancel('paused');

    final progress =
        activeVideoDownloads.remove(videoId) ??
        pausedVideoDownloads[videoId] ??
        0.0;
    pausedVideoDownloads[videoId] = progress;

    final source = _activeVideoSources.remove(videoId);
    if (source != null) {
      source.isDownloading = false;
      source.isPaused = true;
      source.downloadProgress = progress;
      _mirrorVideoState(source);
    }

    final mirror = allVideos.firstWhereOrNull((v) => v.id == videoId);
    if (mirror != null) {
      mirror.isDownloading = false;
      mirror.isPaused = true;
      mirror.downloadProgress = progress;
    }

    final part = await VideoApiService.partFileFor(videoId);
    await _videoStorage.upsertPausedDownload(videoId, progress, part.path);
    onVideoPaused?.call(videoId, progress);
    update();
  }

  Future<void> resumeVideoDownload(Video video) async {
    if (video.isDownloading || activeVideoDownloads.containsKey(video.id)) {
      return;
    }
    video.isPaused = false;
    pausedVideoDownloads.remove(video.id);
    await downloadVideo(video);
  }

  Future<void> _handleVideoDownloadFailure(Video video, [Object? error]) async {
    _videoCancelTokens.remove(video.id);
    _activeVideoSources.remove(video.id);
    activeVideoDownloads.remove(video.id);

    final part = await VideoApiService.partFileFor(video.id);
    final hasPartial = await part.exists() && await part.length() > 0;
    if (hasPartial) {
      video.isDownloading = false;
      video.isPaused = true;
      pausedVideoDownloads[video.id] = video.downloadProgress;
      _mirrorVideoState(video);
      await _videoStorage.upsertPausedDownload(
        video.id,
        video.downloadProgress,
        part.path,
      );
      onVideoPaused?.call(video.id, video.downloadProgress);
      update();
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(
          error ?? 'Download interrupted',
          fallback: 'Download interrupted. You can resume it.',
        ),
      );
      return;
    }

    video.isDownloading = false;
    video.isPaused = false;
    video.downloadProgress = 0.0;
    _mirrorVideoState(video);
    onVideoError?.call(video.id);
    update();
    AppSnackbar.showError(
      'Error',
      ApiErrorMessage.from(
        error ?? 'Failed to download video',
        fallback: 'Failed to download video',
      ),
    );
  }

  Future<void> _restorePausedVideoDownloads() async {
    pausedVideoDownloads.clear();
    final paused = await _videoStorage.getPausedDownloads();
    for (final entry in paused) {
      final rawId = entry['id'];
      final id = rawId is int ? rawId : int.tryParse('$rawId');
      if (id == null) continue;
      final progress = (entry['progress'] as num?)?.toDouble() ?? 0.0;
      final partPath = entry['part_path'] as String?;
      if (partPath != null && !File(partPath).existsSync()) {
        await _videoStorage.removePausedDownload(id);
        continue;
      }
      pausedVideoDownloads[id] = progress;
      final video = allVideos.firstWhereOrNull((v) => v.id == id);
      if (video != null) {
        video.isPaused = true;
        video.isDownloading = false;
        video.downloadProgress = progress;
      }
    }

    try {
      final dir = await VideoApiService.videosDirectory();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.isEmpty
            ? ''
            : entity.uri.pathSegments.last;
        final match = RegExp(r'^video_(\d+)\.mp4\.part$').firstMatch(name);
        if (match == null) continue;
        final id = int.tryParse(match.group(1)!);
        if (id == null || pausedVideoDownloads.containsKey(id)) continue;
        pausedVideoDownloads[id] = 0.0;
        await _videoStorage.upsertPausedDownload(id, 0.0, entity.path);
        final video = allVideos.firstWhereOrNull((v) => v.id == id);
        if (video != null) {
          video.isPaused = true;
          video.isDownloading = false;
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteVideoPartFile(int videoId) async {
    try {
      final part = await VideoApiService.partFileFor(videoId);
      if (await part.exists()) {
        await part.delete();
      }
    } catch (_) {}
  }

  Future<void> _clearVideoTransferState(int videoId) async {
    final token = _videoCancelTokens.remove(videoId);
    if (token != null && !token.isCancelled) {
      token.cancel('cleared');
    }
    activeVideoDownloads.remove(videoId);
    pausedVideoDownloads.remove(videoId);
    _activeVideoSources.remove(videoId);
    await _videoStorage.removePausedDownload(videoId);
    await _deleteVideoPartFile(videoId);
  }

  /// Keeps the matching entry in [allVideos] in sync when the download was
  /// started from ChapterDetailController using a different object instance.
  void _mirrorVideoState(Video source) {
    final mirror = allVideos.firstWhereOrNull((v) => v.id == source.id);
    if (mirror != null && mirror != source) {
      mirror.isDownloading = source.isDownloading;
      mirror.isPaused = source.isPaused;
      mirror.isDownloaded = source.isDownloaded;
      mirror.downloadProgress = source.downloadProgress;
      mirror.filePath = source.filePath;
    }
  }

  void _mirrorNoteState(Note source) {
    final mirror = allNotes.firstWhereOrNull((n) => n.id == source.id);
    if (mirror != null && mirror != source) {
      mirror.isDownloading = source.isDownloading;
      mirror.isDownloaded = source.isDownloaded;
      mirror.downloadProgress = source.downloadProgress;
      mirror.filePath = source.filePath;
    }
  }

  /// Fetches a note into the private in-app cache. Returns true on success.
  Future<bool> ensureNoteCached(Note note) async {
    if (hasDownloadedNoteFile(note) ||
        await NoteFileCache.instance.hasCache(
          note.id,
          storedPath: note.filePath,
        )) {
      if (!note.isDownloaded) {
        note.isDownloaded = true;
        note.filePath ??= await NoteFileCache.instance.cacheFilePath(note.id);
        _mirrorNoteState(note);
        update();
      }
      return true;
    }

    if (note.isDownloading || activeNoteDownloads.containsKey(note.id)) {
      AppSnackbar.showInfo('Info', 'This note is already downloading');
      return false;
    }

    try {
      note.isDownloading = true;
      note.downloadProgress = 0.0;
      activeNoteDownloads[note.id] = 0.0;

      _mirrorNoteState(note);
      update();
      onNoteProgress?.call(note.id, 0.0);

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      var succeeded = false;

      await _noteApiService.downloadNote(
        note.id,
        deviceId: device.id,
        onData: (data, progress) {
          if (data == null) return;
          final p = progress / 100.0;
          note.downloadProgress = p;
          activeNoteDownloads[note.id] = p;

          _mirrorNoteState(note);
          onNoteProgress?.call(note.id, p);
          update();
        },
        onDone: (path) {
          note.filePath = path;
          note.isDownloaded = true;
          note.isDownloading = false;
          note.downloadProgress = 1.0;
          activeNoteDownloads.remove(note.id);

          _mirrorNoteState(note);
          _noteStorage.addDownloadedNote(note.id, path);
          onNoteCompleted?.call(note.id, path);
          update();
          succeeded = true;
        },
        onError: (error) {
          note.isDownloading = false;
          note.downloadProgress = 0.0;
          activeNoteDownloads.remove(note.id);

          _mirrorNoteState(note);
          onNoteError?.call(note.id);
          update();

          AppSnackbar.showError(
            'Error',
            ApiErrorMessage.from(error, fallback: 'Could not download note'),
          );
        },
      );
      return succeeded && hasDownloadedNoteFile(note);
    } catch (e) {
      note.isDownloading = false;
      note.downloadProgress = 0.0;
      activeNoteDownloads.remove(note.id);

      _mirrorNoteState(note);
      onNoteError?.call(note.id);
      update();

      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Could not download note'),
      );
      return false;
    }
  }

  Future<void> downloadNote(Note note) async {
    if (isNoteLocked(note)) {
      AppSnackbar.showWarning(
        'Locked Content',
        'Subscribe to this subject to access all sections.',
      );
      return;
    }

    if (note.isDownloaded && hasDownloadedNoteFile(note)) {
      AppSnackbar.showInfo('Info', 'Note is already downloaded');
      return;
    }

    final cached = await ensureNoteCached(note);
    if (cached) {
      AppSnackbar.showSuccess('Success', 'Note downloaded successfully');
    }
  }

  // Download exam (download questions)
  Future<void> downloadExam(Exam exam) async {
    if (isExamLocked(exam)) {
      AppSnackbar.showWarning('Access Denied', 'This exam is locked and cannot be downloaded');
      return;
    }

    if (exam.isDownloaded) {
      AppSnackbar.showInfo('Info', 'Exam is already downloaded');
      return;
    }

    if (exam.isLoadingQuestion) {
      AppSnackbar.showInfo('Info', 'Exam is already being downloaded');
      return;
    }

    try {
      exam.isLoadingQuestion = true;
      update();

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final questions = await _examApiService.getQuestions(device.id, exam.id);

      logger.i('Downloaded ${questions.length} questions for exam ${exam.id}');

      exam.questions = questions;
      exam.isDownloaded = true;
      exam.isLoadingQuestion = false;

      update();

      await _examStorage.setQuestions(exam.id, questions);

      AppSnackbar.showSuccess('Success', 'Exam downloaded successfully');

      // Refresh exam controller if it exists
      if (Get.isRegistered<ExamController>()) {
        Get.find<ExamController>().refreshExamDownloadStatus();
      }
    } catch (e) {
      exam.isLoadingQuestion = false;
      update();

      logger.e(e);
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Failed to download exam'),
      );
    }
  }

  // Play/Open video
  void playVideo(Video video) {
    if (!video.isDownloaded || video.filePath == null) {
      AppSnackbar.showError('Error', 'Video not downloaded');
      return;
    }

    // Navigate to video player
    Get.to(
      () => VideoPlayerScreen(
        videoUrl: video.filePath!,
        videoTitle: video.title,
        videoId: video.id,
      ),
    );
  }

  // Open note inside the app only (private cache, no public download).
  Future<void> openNote(Note note) async {
    if (isNoteLocked(note)) {
      AppSnackbar.showWarning(
        'Locked Content',
        'Subscribe to this subject to access all sections.',
      );
      return;
    }

    if (!note.isDownloaded || !hasDownloadedNoteFile(note)) {
      AppSnackbar.showWarning(
        'Note Not Available',
        'This note needs to be downloaded first',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final cached = await ensureNoteCached(note);
    if (!cached) return;

    try {
      final viewPath = await NoteFileCache.instance.prepareViewFile(
        note.id,
        storedPath: note.filePath,
      );
      final canonical = await NoteFileCache.instance.cacheFilePath(note.id);
      if (note.filePath != canonical && File(canonical).existsSync()) {
        note.filePath = canonical;
        note.isDownloaded = true;
        await _noteStorage.addDownloadedNote(note.id, canonical);
        _mirrorNoteState(note);
        update();
      }

      Get.to(
        () => PDFReaderScreen(
          pdfUrl: viewPath,
          pdfTitle: note.title,
          pdfId: note.id,
          protectContent: true,
          enableListen: true,
        ),
      );
    } catch (e) {
      logger.e('Failed to open note: $e');
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Could not open note'),
      );
    }
  }

  // Start exam
  Future<void> startExam(Exam exam) async {
    if (isExamLocked(exam)) {
      AppSnackbar.showInfo(
        'Locked Exam',
        'Please unlock this exam before attempting it.',
      );
      return;
    }

    final isCompleted = await _examStorage.isCompleted(exam.id);

    if (isCompleted) {
      Get.dialog(
        AlertDialog(
          title: Text('Retake Exam?'),
          content: Text('Do you want to retake this exam?'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
            TextButton(
              onPressed: () async {
                await _examStorage.clearProgress(exam.id, 'exam');
                await _examStorage.clearProgress(exam.id, 'practice');
                await _examStorage.clearCompleted(exam.id);
                if (Get.isRegistered<ExamController>()) {
                  await Get.find<ExamController>().refreshCompletionBadges();
                }
                Get.back();
                Get.to(() => ExamDetailPage(exam: exam));
              },
              child: Text('Retake'),
            ),
          ],
        ),
      );
      return;
    }

    Get.to(() => ExamDetailPage(exam: exam));
  }

  // Delete video
  void deleteVideo(Video video) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.title}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await _clearVideoTransferState(video.id);

                // Delete file from storage
                if (video.filePath != null) {
                  final file = File(video.filePath!);
                  if (file.existsSync()) {
                    await file.delete();
                  }
                }

                // Remove from local storage
                await _videoStorage.removeDownloadedVideo(video.id);

                // Update video state
                video.isDownloaded = false;
                video.isPaused = false;
                video.isDownloading = false;
                video.filePath = null;
                video.downloadProgress = 0.0;

                update();

                Get.back();
                AppSnackbar.showSuccess('Success', 'Video deleted successfully');
              } catch (e) {
                Get.back();
                AppSnackbar.showError(
                  'Error',
                  ApiErrorMessage.from(e, fallback: 'Failed to delete video'),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Remove the private in-app cache for a note (the note stays on the server).
  void deleteNote(Note note) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove from app'),
        content: Text(
          'Remove the in-app copy of "${note.title}"? You can open it again later. The file is never saved to your phone Downloads.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await NoteFileCache.instance.deleteCache(
                  note.id,
                  storedPath: note.filePath,
                );
                await _noteStorage.removeDownloadedNote(note.id);

                note.isDownloaded = false;
                note.filePath = null;
                note.downloadProgress = 0.0;

                update();

                Get.back();
                AppSnackbar.showSuccess('Removed', 'In-app copy removed');
              } catch (e) {
                Get.back();
                AppSnackbar.showError(
                  'Error',
                  ApiErrorMessage.from(e, fallback: 'Failed to remove note'),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Delete exam
  void deleteExam(Exam exam) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                // Delete all exam data including questions and question images
                await _examStorage.deleteExamData(exam.id);

                // Remove from local storage
                await _examStorage.removeDownloadedExam(exam.id);

                // Update exam state
                exam.isDownloaded = false;
                exam.questions.clear();
                exam.isCompleted = false;
                exam.progress = null;

                // Clear progress and completion status
                await _examStorage.clearProgress(exam.id, 'exam');
                await _examStorage.clearProgress(exam.id, 'practice');
                await _examStorage.clearCompleted(exam.id);

                // Reload exams to ensure UI reflects the changes
                await loadAllExams();

                update();

                Get.back();
                AppSnackbar.showSuccess('Success', 'Exam deleted successfully');
              } catch (e) {
                Get.back();
                AppSnackbar.showError(
                  'Error',
                  ApiErrorMessage.from(e, fallback: 'Failed to delete exam'),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Clear all downloads - Updated to ensure all exam progress is cleared
  void clearAllDownloads() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text(
          'Are you sure you want to delete all downloaded content and progress? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                // Delete all video files
                for (var video in allVideos) {
                  if (video.filePath != null) {
                    final file = File(video.filePath!);
                    if (file.existsSync()) {
                      await file.delete();
                    }
                  }
                  await _clearVideoTransferState(video.id);
                  video.isDownloaded = false;
                  video.isPaused = false;
                  video.isDownloading = false;
                  video.filePath = null;
                  video.downloadProgress = 0.0;
                }

                // Delete all private note caches
                for (var note in allNotes.where((n) => n.isDownloaded)) {
                  await NoteFileCache.instance.deleteCache(
                    note.id,
                    storedPath: note.filePath,
                  );
                  note.isDownloaded = false;
                  note.filePath = null;
                  note.downloadProgress = 0.0;
                }
                await NoteFileCache.instance.deleteAllCaches();

                // Clear exam downloads and ALL progress
                for (var exam in allExams.where((e) => e.isDownloaded)) {
                  exam.isDownloaded = false;
                  exam.questions.clear();
                  exam.isCompleted = false;
                  exam.progress = null;

                  // Delete all exam data including questions and question images
                  await _examStorage.deleteExamData(exam.id);

                  // Clear all progress for this exam (both exam and practice modes)
                  await _examStorage.clearProgress(exam.id, 'exam');
                  await _examStorage.clearProgress(exam.id, 'practice');

                  // Clear completion status
                  await _examStorage.clearCompleted(exam.id);
                }

                // Clear all storage
                await _videoStorage.removeAllDownloadedVideos();
                await _videoStorage.removeAllPausedDownloads();
                await _noteStorage.removeAllDownloadedNotes();
                await _examStorage.removeAllDownloadedExams();

                // Reload exams to ensure UI reflects the changes
                await loadAllExams();

                // Refresh exam controller if it exists to update UI badges
                if (Get.isRegistered<ExamController>()) {
                  await Get.find<ExamController>().refreshCompletionBadges();
                }

                update();

                Get.back();
                AppSnackbar.showSuccess(
                  'Success',
                  'All downloads and progress cleared successfully',
                );
              } catch (e) {
                Get.back();
                logger.e('Error clearing all downloads: $e');
                AppSnackbar.showError(
                  'Error',
                  ApiErrorMessage.from(e, fallback: 'Failed to clear downloads'),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // Clear only videos
  void clearVideosOnly() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Videos'),
        content: const Text(
          'Are you sure you want to delete all downloaded videos? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                // Delete all video files
                for (var video in allVideos) {
                  if (video.filePath != null) {
                    final file = File(video.filePath!);
                    if (file.existsSync()) {
                      await file.delete();
                    }
                  }
                  await _clearVideoTransferState(video.id);
                  video.isDownloaded = false;
                  video.isPaused = false;
                  video.isDownloading = false;
                  video.filePath = null;
                  video.downloadProgress = 0.0;
                }

                // Clear video storage
                await _videoStorage.removeAllDownloadedVideos();
                await _videoStorage.removeAllPausedDownloads();
                update();

                Get.back();
                AppSnackbar.showSuccess('Success', 'All videos cleared successfully');
              } catch (e) {
                Get.back();
                AppSnackbar.showError(
                  'Error',
                  ApiErrorMessage.from(e, fallback: 'Failed to clear videos'),
                );
              }
            },
            child: const Text('Clear Videos'),
          ),
        ],
      ),
    );
  }

  // Clear only exams - Updated to remove all progress
  void clearExamsOnly() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Exams'),
        content: const Text(
          'Are you sure you want to delete all downloaded exams and their progress? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                // Clear exam downloads and reset state, and delete all exam data
                for (var exam in allExams.where((e) => e.isDownloaded)) {
                  exam.isDownloaded = false;
                  exam.questions.clear();
                  exam.isCompleted = false;
                  exam.progress = null;

                  // Delete all exam data including questions and question images
                  await _examStorage.deleteExamData(exam.id);

                  // Clear all progress for this exam (both exam and practice modes)
                  await _examStorage.clearProgress(exam.id, 'exam');
                  await _examStorage.clearProgress(exam.id, 'practice');

                  // Clear completion status
                  await _examStorage.clearCompleted(exam.id);
                }

                // Clear all exam storage
                await _examStorage.removeAllDownloadedExams();

                // Reload exams to ensure UI reflects the changes
                await loadAllExams();

                // Refresh exam controller if it exists to update UI badges
                if (Get.isRegistered<ExamController>()) {
                  await Get.find<ExamController>().refreshCompletionBadges();
                }

                update();

                Get.back();
                AppSnackbar.showSuccess(
                  'Success',
                  'All exams and progress cleared successfully',
                );
              } catch (e) {
                Get.back();
                logger.e('Error clearing exams: $e');
                AppSnackbar.showError(
                  'Error',
                  ApiErrorMessage.from(e, fallback: 'Failed to clear exams and progress'),
                );
              }
            },
            child: const Text('Clear Exams'),
          ),
        ],
      ),
    );
  }

  // Clear only notes
  void clearNotesOnly() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Notes'),
        content: const Text(
          'Remove all in-app note copies? You can open notes again later. Files are never saved to your phone Downloads.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                for (var note in allNotes.where((n) => n.isDownloaded)) {
                  await NoteFileCache.instance.deleteCache(
                    note.id,
                    storedPath: note.filePath,
                  );
                  note.isDownloaded = false;
                  note.filePath = null;
                  note.downloadProgress = 0.0;
                }
                await NoteFileCache.instance.deleteAllCaches();

                await _noteStorage.removeAllDownloadedNotes();
                update();

                Get.back();
                AppSnackbar.showSuccess('Removed', 'In-app note copies removed');
              } catch (e) {
                Get.back();
                AppSnackbar.showError(
                  'Error',
                  ApiErrorMessage.from(e, fallback: 'Failed to clear notes'),
                );
              }
            },
            child: const Text('Clear Notes'),
          ),
        ],
      ),
    );
  }

  // Get downloaded videos
  List<Video> get downloadedVideos =>
      allVideos.where((v) => v.isDownloaded).toList();

  // Get downloaded exams
  List<Exam> get downloadedExams =>
      allExams.where((e) => e.isDownloaded).toList();

  // Get downloaded notes
  List<Note> get downloadedNotes =>
      allNotes.where((n) => n.isDownloaded).toList();

  // Refresh all content
  Future<void> refreshContent() async {
    await loadAllVideos();
    await loadAllExams();
    await loadAllNotes();
  }

  // Enhanced clear options dialog with better UI
  void showClearOptionsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.clear_all_rounded,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Clear Downloads',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose what you want to clear:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),

              // Clear options
              _buildClearOption(
                icon: Icons.video_library_rounded,
                title: 'Videos Only',
                subtitle: '${downloadedVideos.length} downloaded',
                onTap: () {
                  Get.back();
                  clearVideosOnly();
                },
              ),
              const SizedBox(height: 12),
              _buildClearOption(
                icon: Icons.quiz_rounded,
                title: 'Exams Only',
                subtitle: '${downloadedExams.length} downloaded',
                onTap: () {
                  Get.back();
                  clearExamsOnly();
                },
              ),
              const SizedBox(height: 12),
              _buildClearOption(
                icon: Icons.description_rounded,
                title: 'Notes Only',
                subtitle: '${downloadedNotes.length} downloaded',
                onTap: () {
                  Get.back();
                  clearNotesOnly();
                },
              ),
              const SizedBox(height: 12),
              _buildClearOption(
                icon: Icons.delete_forever_rounded,
                title: 'Clear All',
                subtitle: 'Delete everything',
                onTap: () {
                  Get.back();
                  clearAllDownloads();
                },
                isDestructive: true,
              ),

              const SizedBox(height: 24),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
