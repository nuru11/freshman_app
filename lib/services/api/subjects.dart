import 'package:get/get.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'api.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';

class SubjectsService extends GetxController {
  final ApiClient apiClient = ApiClient();

  Future<List<Subject>> getSubjects(
    String deviceId, {
    int? gradeId,
  }) async {
    try {
      final package = Uri.encodeQueryComponent(backendAppPackage);
      final gradeQuery =
          gradeId != null && gradeId > 0 ? 'grade=$gradeId&' : '';
      final response = await apiClient.get(
        '/app/subjects?${gradeQuery}device=$deviceId&app_package=$package',
        authenticated: BaseApiClient.accessToken.isNotEmpty,
      );
      logger.i('Subjects response');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Subject.fromJson(e)).toList();
      } else {
        throw ApiException('Failed to get subjects');
      }
    } catch (e) {
      logger.e(e);
      throw ApiException(e.toString());
    }
  }

  Future<Subject> getSubject(String deviceId, int subjectId) async {
    try {
      final response = await apiClient.get(
        '/app/subjects/$subjectId&device=$deviceId',
      );
      if (response.statusCode == 200) {
        return Subject.fromJson(response.data['data']);
      } else {
        throw ApiException('Failed to get subject');
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
