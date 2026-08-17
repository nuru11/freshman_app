import 'package:dio/dio.dart';
import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/api/file_download_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_academy/utils/utils.dart';
import 'dart:io';

class VideoApiService {
  final ApiClient apiClient = ApiClient();

  static Future<Directory> videosDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory videosDir = Directory('${appDocDir.path}/videos');
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    return videosDir;
  }

  static Future<File> partFileFor(int videoId) async {
    final dir = await videosDirectory();
    return File('${dir.path}/video_$videoId.mp4.part');
  }

  static Future<File> finalFileFor(int videoId) async {
    final dir = await videosDirectory();
    return File('${dir.path}/video_$videoId.mp4');
  }

  Future<List<Video>> getVideos(
    int chapterId, {
    required String deviceId,
  }) async {
    final response = await apiClient.get(
      '/app/videos?device=$deviceId&chapter=$chapterId',
      authenticated: true,
    );
    return (response.data as List).map((e) => Video.fromJson(e)).toList();
  }

  Future<List<Video>> getAllVideos({
    required int gradeId,
    required String deviceId,
  }) async {
    final queryParams = {'device': deviceId, 'grade': gradeId};

    final response = await apiClient.get(
      '/app/videos',
      queryParameters: queryParams,
      authenticated: true,
    );
    return (response.data as List).map((e) => Video.fromJson(e)).toList();
  }

  Future<Video> getVideo(int videoId, {required String deviceId}) async {
    final response = await apiClient.get(
      '/app/videos/$videoId?device=$deviceId',
      authenticated: true,
    );

    logger.d(response.data);

    if (response.statusCode == 200) {
      return Video.fromJson(response.data);
    }

    throw ApiException(response.data['detail'] ?? 'Failed to get video');
  }

  Future<void> downloadVideo(
    int videoId, {
    required String deviceId,
    required Function(String?, double) onData,
    required Function(String) onDone,
    required Function(String) onError,
    CancelToken? cancelToken,
    int startByte = 0,
  }) async {
    try {
      final response = await apiClient.get(
        '/app/videos/$videoId?device=$deviceId',
        authenticated: true,
      );
      logger.d(response.data);
      if (response.statusCode != 200) {
        throw ApiException(
          response.data['detail'] ?? 'Failed to download video',
        );
      }

      final rawFile = response.data['file'];

      if (rawFile == null) {
        throw ApiException('Locked content');
      }

      final String url = rawFile.toString();

      final Directory videosDir = await videosDirectory();
      final String fileName = 'video_$videoId.mp4';
      final String partPath = '${videosDir.path}/$fileName.part';
      final String fullPath = '${videosDir.path}/$fileName';

      final resolvedUrl = FileDownloadUtil.resolveDownloadUrl(url);

      logger.d('Downloading video to: $partPath');
      logger.d('Downloading video from: $resolvedUrl');

      final path = await FileDownloadUtil.downloadToFile(
        dio: apiClient.dio,
        absoluteUrl: resolvedUrl,
        savePath: partPath,
        progressName: fileName,
        onProgress: onData,
        cancelToken: cancelToken,
        startByte: startByte,
      );

      final part = File(path);
      final dest = File(fullPath);
      if (await dest.exists()) {
        await dest.delete();
      }
      await part.rename(fullPath);
      logger.d('Video downloaded to: $fullPath');
      onDone(fullPath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return;
      }
      logger.e('Error in downloadVideo: $e');
      onError(e.toString());
    } catch (e) {
      logger.e('Error in downloadVideo: $e');
      onError(e.toString());
    }
  }
}
