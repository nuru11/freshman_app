import 'package:get/get.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'api.dart';
import '../../models/grade.dart';
import '../../utils/utils.dart';

class GradeService extends GetxController {
  final ApiClient apiClient = ApiClient();

  Future<List<Grade>> getGrades(String appPackage) async {
    try {
      final response = await apiClient.get(
        '/app/grades/?app_package=$appPackage',
        authenticated: false,
      );

      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Grade.fromJson(e)).toList();
      }

      logger.e(response.data);

      throw ApiException('Failed to load grades');
    } catch (e) {
      logger.e(e);
      throw ApiException('Failed to load grades');
    }
  }
}
