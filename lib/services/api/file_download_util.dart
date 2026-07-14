import 'package:dio/dio.dart';
import 'package:vector_academy/utils/constants/constants.dart';

/// Helpers for saving remote files into app storage on iOS/macOS/desktop where
/// [flutter_file_downloader] does not run (Android-only plugin).
class FileDownloadUtil {
  FileDownloadUtil._();

  /// Resolves relative API paths against [defaultApiURL].
  static String resolveDownloadUrl(String url) {
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final base = defaultApiURL.endsWith('/')
        ? defaultApiURL.substring(0, defaultApiURL.length - 1)
        : defaultApiURL;
    final path = u.startsWith('/') ? u : '/$u';
    return '$base$path';
  }

  /// Downloads to [savePath]. [onProgress] receives 0–100 like flutter_file_downloader.
  static Future<String> downloadToFile({
    required Dio dio,
    required String absoluteUrl,
    required String savePath,
    required String progressName,
    required void Function(String? name, double progressPercent) onProgress,
  }) async {
    final uri = Uri.parse(absoluteUrl);
    final base = Uri.parse(defaultApiURL);
    final sameOrigin = uri.host.isEmpty || uri.host == base.host;

    final options = Options(
      receiveTimeout: const Duration(minutes: 30),
      headers: sameOrigin ? <String, dynamic>{'Authorization': 'Bearer'} : null,
    );

    await dio.download(
      absoluteUrl,
      savePath,
      options: options,
      onReceiveProgress: (received, total) {
        if (total <= 0) {
          onProgress(progressName, 0);
          return;
        }
        onProgress(progressName, (received / total) * 100);
      },
    );

    return savePath;
  }
}
