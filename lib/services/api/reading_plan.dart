import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_academy/models/reading_premium.dart';
import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/note_file_cache.dart';
import 'package:vector_academy/utils/utils.dart';

class ReadingPlanService extends GetxController {
  final ApiClient apiClient = ApiClient();

  static int cacheId(int documentId) => 5000000 + documentId;

  Future<List<ReadingPlanDocument>> listDocuments() async {
    try {
      final response = await apiClient.get(
        '/app/reading-plans/',
        authenticated: true,
      );
      if (response.statusCode == 403) return [];
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => ReadingPlanDocument.fromJson(e))
            .toList();
      }
      throw ApiException(
        ApiErrorMessage.fromData(response.data) ?? 'Failed to load reading plans',
      );
    } catch (e) {
      logger.e('Error loading reading plans: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load reading plans');
    }
  }

  Future<ReadingPlanDocument> markRead(int id) async {
    final response = await apiClient.post(
      '/app/reading-plans/$id/mark-read/',
      authenticated: true,
    );
    if (response.statusCode == 200) {
      return ReadingPlanDocument.fromJson(response.data);
    }
    throw ApiException(
      ApiErrorMessage.fromData(response.data) ?? 'Failed to mark as read',
    );
  }

  Future<String> downloadForReading(int id) async {
    final cachedId = cacheId(id);
    if (await NoteFileCache.instance.hasCache(cachedId)) {
      return NoteFileCache.instance.prepareViewFile(cachedId);
    }

    final response = await apiClient.dio.get<List<int>>(
      '/app/reading-plans/$id/file/',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Authorization': 'Bearer'},
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw ApiException('Failed to download reading plan PDF');
    }

    final temp = await getTemporaryDirectory();
    final plainPath = '${temp.path}/reading_plan_$id.pdf';
    await File(plainPath).writeAsBytes(response.data!, flush: true);
    await NoteFileCache.instance.storeFromPlaintext(cachedId, plainPath);
    try {
      await File(plainPath).delete();
    } catch (_) {}
    return NoteFileCache.instance.prepareViewFile(cachedId);
  }

  Future<UserTelegramUpdate> updateTelegramHandle(String handle) async {
    final response = await apiClient.patch(
      '/auth/me/update/',
      data: {'telegram_handle': handle},
      authenticated: true,
    );
    if (response.statusCode == 200) {
      return UserTelegramUpdate(
        handle: response.data['telegram_handle'] as String? ?? handle,
      );
    }
    throw ApiException(
      ApiErrorMessage.fromData(response.data) ?? 'Failed to save Telegram',
    );
  }
}

class UserTelegramUpdate {
  final String handle;
  UserTelegramUpdate({required this.handle});
}
