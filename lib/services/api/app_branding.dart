import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/api.dart';

class AppBrandingService {
  final ApiClient _apiClient = ApiClient();

  Future<AppBranding?> getAppBranding(String appPackage) async {
    final response = await _apiClient.get(
      '/app/app-brandings/',
      authenticated: false,
      queryParameters: {'app_package': appPackage},
    );

    if (response.statusCode == 200 && response.data is List) {
      final List<dynamic> items = response.data as List<dynamic>;
      if (items.isEmpty) {
        return null;
      }
      return AppBranding.fromJson(items.first as Map<String, dynamic>);
    }

    return null;
  }
}
