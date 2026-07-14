import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/exceptions.dart';

class AppHeaderTextService {
  final ApiClient apiClient = ApiClient();

  Future<List<AppHeaderText>> getAppHeaderTexts(int gradeId) async {
    final response = await apiClient.get(
      '/app/app-header-texts/',
      authenticated: false,
      queryParameters: {'grade': gradeId},
    );
    if (response.statusCode == 200) {
      return (response.data as List)
          .map((e) => AppHeaderText.fromJson(e))
          .toList();
    }
    throw ApiException(
      response.data['detail'] ?? 'Failed to get app header texts',
    );
  }
}
