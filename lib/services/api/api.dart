import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import "package:vector_academy/utils/utils.dart";
import 'package:flutter/material.dart';

class BaseApiClient {
  final String baseUrl = defaultApiURL;
  static String accessToken = '';
  static String refreshToken = '';
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: defaultApiURL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 500,
      maxRedirects: 5,
      followRedirects: true,
    ),
  );

  // Initialize Dio with interceptors for authentication
  void _initializeDio() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add request interceptor for authentication
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Only add bearer token if explicitly requested via headers
          // Check if Authorization header is explicitly set to use token
          if (options.headers.containsKey('Authorization') &&
              options.headers['Authorization'] == 'Bearer') {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors and attempt token refresh
          if (error.response?.statusCode == 401 && refreshToken.isNotEmpty) {
            try {
              Get.snackbar(
                'Error',

                'Unauthorized',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );

              // Get.offAllNamed(VIEWS.login.path);
              final newToken = await _refreshToken();
              if (newToken != null) {
                // Retry the original request with new token
                final originalRequest = error.requestOptions;
                originalRequest.headers['Authorization'] = 'Bearer $newToken';
                final response = await dio.fetch(originalRequest);
                handler.resolve(response);
                return;
              }
            } catch (e) {
              // Token refresh failed, proceed with error
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // Refresh token method
  Future<String?> _refreshToken() async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': ''}), // No auth for refresh
      );

      if (response.statusCode == 200) {
        accessToken = response.data['access_token'] ?? '';
        refreshToken = response.data['refresh_token'] ?? refreshToken;
        return accessToken;
      }
    } catch (e) {
      // Clear tokens on refresh failure
      accessToken = '';
      refreshToken = '';
    }
    return null;
  }

  // Set authentication tokens
  static void setTokens(String access, String refresh) {
    accessToken = access;
    refreshToken = refresh;
  }

  // Clear authentication tokens
  void clearTokens() {
    accessToken = '';
    refreshToken = '';
  }

  // GET request (unauthenticated by default)
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    final response = await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );

    return response;
  }

  // POST request (unauthenticated by default)
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    final response = await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  // PUT request (unauthenticated by default)
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    final response = await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  // DELETE request (unauthenticated by default)
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    final response = await dio.delete(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  // PATCH request (unauthenticated by default)
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    final response = await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  Future<Response> postMultipart(
    String path, {
    required File file,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
  }) async {
    final formData = FormData.fromMap({
      'receipt': await MultipartFile.fromFile(file.path),
      ...?additionalData,
    });

    final response = await dio.post(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return response;
  }

  // File upload method
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    method = 'POST',
    ProgressCallback? onSendProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    // Create form data
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        filePath,
        filename: file.path.split('/').last,
      ),
      ...?additionalData,
    });

    Response response;

    if (method == 'PATCH') {
      response = await dio.patch(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
    } else if (method == 'PUT') {
      response = await dio.put(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
    } else {
      response = await dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
    }
    return response;
  }

  // Multiple files upload method
  Future<Response> uploadMultipleFiles(
    String path, {
    required List<String> filePaths,
    String fieldName = 'files',
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    ProgressCallback? onSendProgress,
  }) async {
    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    // Create form data with multiple files
    final formDataMap = <String, dynamic>{...?additionalData};

    final files = <MultipartFile>[];
    for (final filePath in filePaths) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      files.add(
        await MultipartFile.fromFile(
          filePath,
          filename: file.path.split('/').last,
        ),
      );
    }

    formDataMap[fieldName] = files;
    final formData = FormData.fromMap(formDataMap);

    final response = await dio.post(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: options,
      onSendProgress: onSendProgress,
    );
    return response;
  }

  // Upload file from bytes (useful for camera captures)
  Future<Response> uploadFileFromBytes(
    String path, {
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    ProgressCallback? onSendProgress,
  }) async {
    final options = Options();
    if (authenticated) {
      options.headers = {'Authorization': 'Bearer'};
    }

    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename),
      ...?additionalData,
    });

    final response = await dio.post(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: options,
      onSendProgress: onSendProgress,
    );
    return response;
  }
}

class ApiClient extends BaseApiClient {
  ApiClient() {
    _initializeDio();
  }
}
