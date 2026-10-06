import 'package:vector_academy/services/api/api.dart';

class AppUpdateDecision {
  const AppUpdateDecision({
    required this.mode,
    required this.title,
    required this.message,
    required this.storeUrl,
  });

  final String mode;
  final String title;
  final String message;
  final String storeUrl;

  bool get isRequired => mode == 'required';
  bool get isOptional => mode == 'optional';

  factory AppUpdateDecision.fromJson(Map<String, dynamic> json) {
    return AppUpdateDecision(
      mode: json['mode'] as String? ?? 'none',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      storeUrl: json['store_url'] as String? ?? '',
    );
  }
}

class AppVersionService {
  final ApiClient _apiClient = ApiClient();

  Future<AppUpdateDecision?> check({
    required String appPackage,
    required String platform,
    required String version,
  }) async {
    final response = await _apiClient.get(
      '/app/app-version/',
      authenticated: false,
      queryParameters: {
        'app_package': appPackage,
        'platform': platform,
        'version': version,
      },
    );
    if (response.statusCode == 200 && response.data is Map) {
      return AppUpdateDecision.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    return null;
  }
}
