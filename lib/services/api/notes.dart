import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/api/file_download_util.dart';
import 'package:vector_academy/services/note_file_cache.dart';

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

  /// Fetches a note PDF into the encrypted private cache. The file is never
  /// written to public Downloads storage.
  Future<void> downloadNote(
    int noteId, {
    required String deviceId,
    required Function(String?, double) onData,
    required Function(String) onDone,
    required Function(String) onError,
  }) async {
    String? tmpPath;
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

      final supportDir = await getApplicationSupportDirectory();
      final tmpDir = Directory('${supportDir.path}/note_cache');
      if (!await tmpDir.exists()) {
        await tmpDir.create(recursive: true);
      }
      tmpPath = '${tmpDir.path}/.tmp_note_$noteId.pdf';

      await FileDownloadUtil.downloadToFile(
        dio: apiClient.dio,
        absoluteUrl: resolvedUrl,
        savePath: tmpPath,
        progressName: 'note_$noteId',
        onProgress: onData,
      );

      final cachedPath = await NoteFileCache.instance.storeFromPlaintext(
        noteId,
        tmpPath,
      );
      onDone(cachedPath);
    } catch (e) {
      onError(e.toString());
    } finally {
      if (tmpPath != null) {
        try {
          final tmp = File(tmpPath);
          if (await tmp.exists()) {
            await tmp.delete();
          }
        } catch (_) {}
      }
    }
  }
}
