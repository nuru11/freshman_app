import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/services/services.dart';
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
  final Map<int, double> activeNoteDownloads = {};

  // Callbacks set by ChapterDetailController so progress can be pushed back
  // without creating a circular import.
  void Function(int videoId, double progress)? onVideoProgress;
  void Function(int videoId, String filePath)? onVideoCompleted;
  void Function(int videoId)? onVideoError;
  void Function(int noteId, double progress)? onNoteProgress;
  void Function(int noteId, String filePath)? onNoteCompleted;
  void Function(int noteId)? onNoteError;

  User? _user;

  bool get hasFullAccessOverride =>
      hasFullAccessOverrideForPhone(_user?.phoneNumber);

  bool isVideoLocked(Video video) {
    if (hasFullAccessOverride) {
      return false;
    }
    if (hasDownloadedVideoFile(video)) {
      return false;
    }
    return video.isLocked;
  }

  bool isNoteLocked(Note note) {
    if (hasFullAccessOverride) {
      return false;
    }
    if (hasDownloadedNoteFile(note)) {
      return false;
    }
    return note.isLocked;
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
      Get.snackbar('Info', 'Video is already downloaded');
      return;
    }

    if (video.isDownloading || activeVideoDownloads.containsKey(video.id)) {
      Get.snackbar('Info', 'Video is already being downloaded');
      return;
    }

    try {
      video.isDownloading = true;
      video.downloadProgress = 0.0;
      activeVideoDownloads[video.id] = 0.0;

      // Mirror state on the allVideos entry if different object
      _mirrorVideoState(video);
      update();
      // Notify listeners (e.g. ChapterDetailController) so UI rebuilds before first file progress event.
      onVideoProgress?.call(video.id, 0.0);

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');

      await _videoApiService.downloadVideo(
        video.id,
        deviceId: device.id,
        onData: (data, progress) {
          // Skip flutter_file_downloader's first callback (download queue id, no filename).
          if (data == null) return;
          final p = progress / 100.0;
          video.downloadProgress = p;
          activeVideoDownloads[video.id] = p;

          _mirrorVideoState(video);
          onVideoProgress?.call(video.id, p);
          update();
        },
        onDone: (path) {
          video.filePath = path;
          video.isDownloaded = true;
          video.isDownloading = false;
          video.downloadProgress = 1.0;
          activeVideoDownloads.remove(video.id);

          _mirrorVideoState(video);
          _videoStorage.addDownloadedVideo(video.id, path);
          onVideoCompleted?.call(video.id, path);
          update();

          Get.snackbar(
            'Success',
            'Video downloaded successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
        onError: (error) {
          video.isDownloading = false;
          video.downloadProgress = 0.0;
          activeVideoDownloads.remove(video.id);

          _mirrorVideoState(video);
          onVideoError?.call(video.id);
          update();

          Get.snackbar('Error', 'Failed to download video');
        },
      );
    } catch (e) {
      video.isDownloading = false;
      video.downloadProgress = 0.0;
      activeVideoDownloads.remove(video.id);

      _mirrorVideoState(video);
      onVideoError?.call(video.id);
      update();

      Get.snackbar('Error', 'Failed to download video');
    }
  }

  /// Keeps the matching entry in [allVideos] in sync when the download was
  /// started from ChapterDetailController using a different object instance.
  void _mirrorVideoState(Video source) {
    final mirror = allVideos.firstWhereOrNull((v) => v.id == source.id);
    if (mirror != null && mirror != source) {
      mirror.isDownloading = source.isDownloading;
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

  // Download note
  Future<void> downloadNote(Note note) async {
    if (note.isDownloaded) {
      Get.snackbar('Info', 'Note is already downloaded');
      return;
    }

    if (note.isDownloading || activeNoteDownloads.containsKey(note.id)) {
      Get.snackbar('Info', 'Note is already being downloaded');
      return;
    }

    try {
      note.isDownloading = true;
      note.downloadProgress = 0.0;
      activeNoteDownloads[note.id] = 0.0;

      _mirrorNoteState(note);
      update();
      // Notify listeners (e.g. ChapterDetailController) so UI rebuilds before first file progress event.
      onNoteProgress?.call(note.id, 0.0);

      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');

      await _noteApiService.downloadNote(
        note.id,
        deviceId: device.id,
        onData: (data, progress) {
          // Skip flutter_file_downloader's first callback (download queue id, no filename).
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

          Get.snackbar(
            'Success',
            'Note downloaded successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
        onError: (error) {
          note.isDownloading = false;
          note.downloadProgress = 0.0;
          activeNoteDownloads.remove(note.id);

          _mirrorNoteState(note);
          onNoteError?.call(note.id);
          update();

          Get.snackbar('Error', 'Failed to download note');
        },
      );
    } catch (e) {
      note.isDownloading = false;
      note.downloadProgress = 0.0;
      activeNoteDownloads.remove(note.id);

      _mirrorNoteState(note);
      onNoteError?.call(note.id);
      update();

      Get.snackbar('Error', 'Failed to download note');
    }
  }

  // Download exam (download questions)
  Future<void> downloadExam(Exam exam) async {
    if (isExamLocked(exam)) {
      Get.snackbar(
        'Access Denied',
        'This exam is locked and cannot be downloaded',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (exam.isDownloaded) {
      Get.snackbar('Info', 'Exam is already downloaded');
      return;
    }

    if (exam.isLoadingQuestion) {
      Get.snackbar('Info', 'Exam is already being downloaded');
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

      Get.snackbar(
        'Success',
        'Exam downloaded successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh exam controller if it exists
      if (Get.isRegistered<ExamController>()) {
        Get.find<ExamController>().refreshExamDownloadStatus();
      }
    } catch (e) {
      exam.isLoadingQuestion = false;
      update();

      logger.e(e);
      Get.snackbar('Error', 'Failed to download exam');
    }
  }

  // Play/Open video
  void playVideo(Video video) {
    if (!video.isDownloaded || video.filePath == null) {
      Get.snackbar('Error', 'Video not downloaded');
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

  // Open note
  void openNote(Note note) {
    if (!note.isDownloaded || note.filePath == null) {
      Get.snackbar('Error', 'Note not downloaded');
      return;
    }

    // Navigate to PDF reader or appropriate viewer

    if (note.filePath != null) {
      Get.to(
        () => PDFReaderScreen(
          pdfUrl: note.filePath!,
          pdfTitle: note.title,
          pdfId: note.id,
        ),
      );
    }
  }

  // Start exam
  Future<void> startExam(Exam exam) async {
    if (isExamLocked(exam)) {
      Get.snackbar(
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
                video.filePath = null;
                video.downloadProgress = 0.0;

                update();

                Get.back();
                Get.snackbar(
                  'Success',
                  'Video deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                Get.snackbar('Error', 'Failed to delete video');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete note
  void deleteNote(Note note) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                // Delete file from storage
                if (note.filePath != null) {
                  final file = File(note.filePath!);
                  if (file.existsSync()) {
                    await file.delete();
                  }
                }

                // Remove from local storage
                await _noteStorage.removeDownloadedNote(note.id);

                // Update note state
                note.isDownloaded = false;
                note.filePath = null;
                note.downloadProgress = 0.0;

                update();

                Get.back();
                Get.snackbar(
                  'Success',
                  'Note deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                Get.snackbar('Error', 'Failed to delete note');
              }
            },
            child: const Text('Delete'),
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
                Get.snackbar(
                  'Success',
                  'Exam deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                Get.snackbar('Error', 'Failed to delete exam');
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
                for (var video in allVideos.where((v) => v.isDownloaded)) {
                  if (video.filePath != null) {
                    final file = File(video.filePath!);
                    if (file.existsSync()) {
                      await file.delete();
                    }
                  }
                  video.isDownloaded = false;
                  video.filePath = null;
                  video.downloadProgress = 0.0;
                }

                // Delete all note files
                for (var note in allNotes.where((n) => n.isDownloaded)) {
                  if (note.filePath != null) {
                    final file = File(note.filePath!);
                    if (file.existsSync()) {
                      await file.delete();
                    }
                  }
                  note.isDownloaded = false;
                  note.filePath = null;
                  note.downloadProgress = 0.0;
                }

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
                Get.snackbar(
                  'Success',
                  'All downloads and progress cleared successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                logger.e('Error clearing all downloads: $e');
                Get.snackbar('Error', 'Failed to clear downloads');
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
                for (var video in allVideos.where((v) => v.isDownloaded)) {
                  if (video.filePath != null) {
                    final file = File(video.filePath!);
                    if (file.existsSync()) {
                      await file.delete();
                    }
                  }
                  video.isDownloaded = false;
                  video.filePath = null;
                  video.downloadProgress = 0.0;
                }

                // Clear video storage
                await _videoStorage.removeAllDownloadedVideos();
                update();

                Get.back();
                Get.snackbar(
                  'Success',
                  'All videos cleared successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                Get.snackbar('Error', 'Failed to clear videos');
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
                Get.snackbar(
                  'Success',
                  'All exams and progress cleared successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                logger.e('Error clearing exams: $e');
                Get.snackbar('Error', 'Failed to clear exams and progress');
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
          'Are you sure you want to delete all downloaded notes? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                // Delete all note files
                for (var note in allNotes.where((n) => n.isDownloaded)) {
                  if (note.filePath != null) {
                    final file = File(note.filePath!);
                    if (file.existsSync()) {
                      await file.delete();
                    }
                  }
                  note.isDownloaded = false;
                  note.filePath = null;
                  note.downloadProgress = 0.0;
                }

                // Clear note storage
                await _noteStorage.removeAllDownloadedNotes();
                update();

                Get.back();
                Get.snackbar(
                  'Success',
                  'All notes cleared successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back();
                Get.snackbar('Error', 'Failed to clear notes');
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
