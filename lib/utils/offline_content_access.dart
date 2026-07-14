import 'dart:io';

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
