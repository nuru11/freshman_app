import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() {
    return message;
  }
}

/// Extracts a human-readable message from API response bodies / Dio errors.
class ApiErrorMessage {
  static String from(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is ApiException) {
      final message = error.message.trim();
      return message.isEmpty ? fallback : message;
    }

    if (error is DioException) {
      final fromResponse = fromData(error.response?.data);
      if (fromResponse != null) return fromResponse;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.badResponse:
          return fallback;
        case DioExceptionType.badCertificate:
          return 'Secure connection failed. Please try again.';
        case DioExceptionType.unknown:
          final message = error.message?.trim();
          if (message != null && message.isNotEmpty) return message;
          return fallback;
      }
    }

    final fromDataMessage = fromData(error);
    if (fromDataMessage != null) return fromDataMessage;

    final asString = error.toString().trim();
    if (asString.isEmpty || asString == 'null' || asString == 'Instance of \'ApiException\'') {
      return fallback;
    }
    return asString;
  }

  static String? fromData(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (data is List && data.isNotEmpty) {
      return fromData(data.first);
    }

    if (data is! Map) return null;

    final map = Map<String, dynamic>.from(data);

    final detail = map['detail'];
    final fromDetail = fromData(detail);
    if (fromDetail != null) return fromDetail;

    final error = map['error'];
    if (error is Map) {
      final nested = fromData(error['message']) ?? fromData(error['detail']);
      if (nested != null) return nested;
    } else {
      final fromError = fromData(error);
      if (fromError != null) return fromError;
    }

    final message = fromData(map['message']);
    if (message != null) return message;

    // Common field-error shapes from DRF, e.g. {"phone_number": ["..."]}
    for (final entry in map.entries) {
      final key = entry.key;
      if (key == 'status' || key == 'code' || key == 'success') continue;
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        final fieldMessage = fromData(value.first);
        if (fieldMessage != null) {
          return _formatFieldError(key, fieldMessage);
        }
      } else if (value is String && value.trim().isNotEmpty) {
        return _formatFieldError(key, value.trim());
      }
    }

    return null;
  }

  static String _formatFieldError(String key, String message) {
    final label = key
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    return '$label: $message';
  }
}
