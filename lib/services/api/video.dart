import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/api/file_download_util.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_academy/utils/utils.dart';
import 'dart:io';

class VideoApiService {
  final ApiClient apiClient = ApiClient();

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

      // Get app documents directory for storing videos
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videosDir = '${appDocDir.path}/videos';

      // Create videos directory if it doesn't exist
      final Directory videosDirObj = Directory(videosDir);
      if (!await videosDirObj.exists()) {
        await videosDirObj.create(recursive: true);
      }

      // Generate filename from URL or use video ID
      final String fileName = 'video_$videoId.mp4';
      final String fullPath = '$videosDir/$fileName';

      final resolvedUrl = FileDownloadUtil.resolveDownloadUrl(url);

      logger.d('Downloading video to: $fullPath');
      logger.d('Downloading video from: $resolvedUrl');

      // flutter_file_downloader is Android-only; use Dio everywhere else (iOS, desktop, …).
      if (!Platform.isAndroid) {
        final path = await FileDownloadUtil.downloadToFile(
          dio: apiClient.dio,
          absoluteUrl: resolvedUrl,
          savePath: fullPath,
          progressName: fileName,
          onProgress: onData,
        );
        logger.d('Video downloaded to: $path');
        onDone(path);
        return;
      }

      final File? file = await FileDownloader.downloadFile(
        url: resolvedUrl,
        name: fileName,
        subPath: 'videos',
        downloadDestination: DownloadDestinations.appFiles,
        onProgress: onData,
        onDownloadError: (String error) {
          logger.e('Download error: $error');
          onError(error);
        },
      );
      if (file != null) {
        logger.d('Video downloaded to: ${file.path}');
        onDone(file.path);
      }
    } catch (e) {
      logger.e('Error in downloadVideo: $e');
      onError(e.toString());
    }
  }
}
