import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/utils.dart';

class GeneralController extends GetxController {
  bool _isGradeLoading = false;
  bool get isGradeLoading => _isGradeLoading;

  List<Grade> _grades = [];
  List<Grade> get grades => _grades;

  Future<void> loadGrades() async {
    _isGradeLoading = true;
    update();

    try {
      _grades = await GradeService().getGrades(backendAppPackage);
      _grades.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      Get.snackbar('Error', 'Failed to load grades');
    } finally {
      _isGradeLoading = false;
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadGrades();
  }
}
