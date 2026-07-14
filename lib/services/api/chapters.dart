import 'package:get/get.dart';
import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/exceptions.dart';

class ChaptersService extends GetxController {
  final ApiClient apiClient = ApiClient();

  Future<List<Chapter>> getChapters(int subjectId) async {
    final response = await apiClient.get('/chapters?subject=$subjectId');
    if (response.statusCode == 200) {
      return (response.data as List).map((e) => Chapter.fromJson(e)).toList();
    } else {
      throw ApiException(response.data['message']);
    }
  }
}
