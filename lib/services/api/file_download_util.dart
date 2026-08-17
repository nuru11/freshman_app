import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vector_academy/utils/constants/constants.dart';

/// Helpers for saving remote files into app storage.
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

  static int? parseContentRangeTotal(String? header) {
    if (header == null || header.isEmpty) return null;
    final slash = header.lastIndexOf('/');
    if (slash < 0 || slash == header.length - 1) return null;
    final total = header.substring(slash + 1).trim();
    if (total == '*') return null;
    return int.tryParse(total);
  }

  /// Downloads to [savePath]. [onProgress] receives 0–100.
  ///
  /// Pass [startByte] > 0 to resume via HTTP Range. If the server returns 206
  /// the existing file is appended; a 200 response overwrites from the start.
  /// [DioExceptionType.cancel] is rethrown so callers can treat pause separately.
  static Future<String> downloadToFile({
    required Dio dio,
    required String absoluteUrl,
    required String savePath,
    required String progressName,
    required void Function(String? name, double progressPercent) onProgress,
    CancelToken? cancelToken,
    int startByte = 0,
  }) async {
    final uri = Uri.parse(absoluteUrl);
    final base = Uri.parse(defaultApiURL);
    final sameOrigin = uri.host.isEmpty || uri.host == base.host;

    final headers = <String, dynamic>{};
    if (sameOrigin) {
      headers['Authorization'] = 'Bearer';
    }
    if (startByte > 0) {
      headers[HttpHeaders.rangeHeader] = 'bytes=$startByte-';
    }

    final response = await dio.get<ResponseBody>(
      absoluteUrl,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 30),
        headers: headers,
        validateStatus: (status) =>
            status != null &&
            (status == 200 || status == 206 || status == 416),
      ),
    );

    if (response.statusCode == 416 && startByte > 0) {
      return downloadToFile(
        dio: dio,
        absoluteUrl: absoluteUrl,
        savePath: savePath,
        progressName: progressName,
        onProgress: onProgress,
        cancelToken: cancelToken,
        startByte: 0,
      );
    }

    final status = response.statusCode ?? 200;
    final resume = status == 206 && startByte > 0;
    final offset = resume ? startByte : 0;

    final file = File(savePath);
    if (!resume && await file.exists()) {
      await file.delete();
    }
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.create();
    }

    final contentLengthHeader = response.headers.value(
      Headers.contentLengthHeader,
    );
    final parsedLength = int.tryParse(contentLengthHeader ?? '') ?? -1;
    final bodyLength = response.data?.contentLength ?? -1;
    final contentLength = parsedLength > 0 ? parsedLength : bodyLength;
    final rangeTotal = parseContentRangeTotal(
      response.headers.value(HttpHeaders.contentRangeHeader),
    );

    var totalSize = 0;
    if (rangeTotal != null && rangeTotal > 0) {
      totalSize = rangeTotal;
    } else if (contentLength > 0) {
      totalSize = offset + contentLength;
    }

    final sink = file.openWrite(mode: resume ? FileMode.append : FileMode.write);
    var received = 0;
    try {
      final stream = response.data?.stream;
      if (stream == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Empty download stream',
        );
      }
      await for (final chunk in stream) {
        sink.add(chunk);
        received += chunk.length;
        if (totalSize > 0) {
          final percent = ((offset + received) / totalSize) * 100;
          onProgress(progressName, percent.clamp(0.0, 100.0).toDouble());
        }
      }
      await sink.flush();
      await sink.close();
    } catch (e) {
      try {
        await sink.flush();
        await sink.close();
      } catch (_) {}
      rethrow;
    }

    return savePath;
  }
}
