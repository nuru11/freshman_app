import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vector_academy/models/models.dart';

bool hasDownloadedVideoFile(Video video) {
  return video.isDownloaded &&
      video.filePath != null &&
      video.filePath!.isNotEmpty &&
      File(video.filePath!).existsSync();
}

bool hasDownloadedNoteFile(Note note) {
  return note.isDownloaded &&
      note.filePath != null &&
      note.filePath!.isNotEmpty &&
      File(note.filePath!).existsSync();
}

bool hasDownloadedExamContent(Exam exam) {
  return exam.isDownloaded && exam.questions.isNotEmpty;
}

int? parseStoredId(dynamic raw) {
  if (raw is int) return raw;
  return int.tryParse('$raw');
}

bool storedFileExists(String? path) {
  return path != null && path.isNotEmpty && File(path).existsSync();
}

bool downloadedEntryHasId(dynamic element, int id) {
  if (element is! Map) return false;
  return parseStoredId(element['id']) == id;
}

Future<String> canonicalVideoFilePath(int videoId) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  return '${appDocDir.path}/videos/video_$videoId.mp4';
}

Future<String> canonicalNoteCachePath(int noteId) async {
  final support = await getApplicationSupportDirectory();
  return '${support.path}/note_cache/note_$noteId.dat';
}

Map<int, String> downloadedPathIndex(List<Map<String, dynamic>> entries) {
  final byId = <int, String>{};
  for (final entry in entries) {
    final id = parseStoredId(entry['id']);
    final path = entry['file_path']?.toString();
    if (id != null && path != null && path.isNotEmpty) {
      byId[id] = path;
    }
  }
  return byId;
}

/// Sets [video.filePath] / [video.isDownloaded] from a real on-disk file.
/// Ignores the API `is_downloaded` flag when no local file exists.
Future<bool> hydrateVideoDownloadState(
  Video video, {
  String? storedPath,
}) async {
  if (storedFileExists(storedPath)) {
    video.filePath = storedPath;
    video.isDownloaded = true;
    return true;
  }
  if (storedFileExists(video.filePath)) {
    video.isDownloaded = true;
    return true;
  }
  final canonical = await canonicalVideoFilePath(video.id);
  if (storedFileExists(canonical)) {
    video.filePath = canonical;
    video.isDownloaded = true;
    return true;
  }
  video.filePath = null;
  video.isDownloaded = false;
  return false;
}

/// Sets [note.filePath] / [note.isDownloaded] from the encrypted cache or a
/// stored path. Always prefers the canonical `note_{id}.dat` when present.
Future<bool> hydrateNoteDownloadState(
  Note note, {
  String? storedPath,
}) async {
  final canonical = await canonicalNoteCachePath(note.id);
  if (storedFileExists(canonical)) {
    note.filePath = canonical;
    note.isDownloaded = true;
    return true;
  }
  if (storedFileExists(storedPath)) {
    note.filePath = storedPath;
    note.isDownloaded = true;
    return true;
  }
  if (storedFileExists(note.filePath)) {
    note.isDownloaded = true;
    return true;
  }
  note.filePath = null;
  note.isDownloaded = false;
  return false;
}

Future<void> hydrateVideoListDownloadState(
  List<Video> videos,
  List<Map<String, dynamic>> downloadedIndex,
) async {
  final byId = downloadedPathIndex(downloadedIndex);
  for (final video in videos) {
    await hydrateVideoDownloadState(video, storedPath: byId[video.id]);
  }
}

Future<void> hydrateNoteListDownloadState(
  List<Note> notes,
  List<Map<String, dynamic>> downloadedIndex,
) async {
  final byId = downloadedPathIndex(downloadedIndex);
  for (final note in notes) {
    await hydrateNoteDownloadState(note, storedPath: byId[note.id]);
  }
}
