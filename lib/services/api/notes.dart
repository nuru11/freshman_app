import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/api/file_download_util.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class NoteService {
  final ApiClient apiClient = ApiClient();

  Future<List<Note>> getNotes(String deviceId, {required int chapterId}) async {
    final response = await apiClient.get(
      '/app/notes?chapter=$chapterId&device=$deviceId',
      authenticated: true,
    );
    return (response.data as List).map((e) => Note.fromJson(e)).toList();
  }

  Future<List<Note>> getAllNotes(String deviceId, {int? gradeId}) async {
    final queryParams = <String, dynamic>{};
    if (gradeId != null) {
      queryParams['grade'] = gradeId;
    }
    final response = await apiClient.get(
      '/app/notes?device=$deviceId',
      authenticated: true,
      queryParameters: queryParams,
    );
    if (response.statusCode != 200) {
      throw ApiException('Failed to get all notes');
    }
    return (response.data as List).map((e) => Note.fromJson(e)).toList();
  }

  Future<void> downloadNote(
    int noteId, {
    required String deviceId,
    required Function(String?, double) onData,
    required Function(String) onDone,
    required Function(String) onError,
  }) async {
    try {
      final response = await apiClient.get(
        '/app/notes/$noteId?device=$deviceId',
        authenticated: true,
      );
      if (response.statusCode != 200) {
        throw ApiException('Failed to download note');
      }

      final rawFile = response.data['file'];
      if (rawFile == null) {
        throw ApiException('Note file not available');
      }

      final String url = rawFile.toString();
      final resolvedUrl = FileDownloadUtil.resolveDownloadUrl(url);

      final appDocDir = await getApplicationDocumentsDirectory();
      final notesDir = '${appDocDir.path}/notes';
      final notesDirObj = Directory(notesDir);
      if (!await notesDirObj.exists()) {
        await notesDirObj.create(recursive: true);
      }

      String fileName = 'note_$noteId.pdf';
      final segments = Uri.parse(resolvedUrl).pathSegments;
      if (segments.isNotEmpty) {
        final last = segments.last;
        if (last.contains('.')) {
          fileName = last;
        }
      }

      final fullPath = '$notesDir/$fileName';
      final progressName = fileName;

      if (!Platform.isAndroid) {
        final path = await FileDownloadUtil.downloadToFile(
          dio: apiClient.dio,
          absoluteUrl: resolvedUrl,
          savePath: fullPath,
          progressName: progressName,
          onProgress: onData,
        );
        onDone(path);
        return;
      }

      final File? file = await FileDownloader.downloadFile(
        url: resolvedUrl,
        name: fileName,
        subPath: 'notes',
        downloadDestination: DownloadDestinations.appFiles,
        onProgress: onData,
        onDownloadError: onError,
      );
      if (file != null) {
        onDone(file.path);
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}
