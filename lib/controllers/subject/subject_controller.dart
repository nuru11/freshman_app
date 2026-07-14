import 'package:get/get.dart';
import 'package:vector_academy/views/subject/subject_detail.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'dart:async';

class SubjectController extends GetxController {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;

  User? _user;
  User? get user => _user;
  bool get hasFullAccessOverride =>
      hasFullAccessOverrideForPhone(_user?.phoneNumber);
  late StreamSubscription<InternetStatus> _internetStatusSubscription;
  @override
  void onInit() async {
    super.onInit();
    _user = await HiveUserStorage().getUser();
    HiveUserStorage().listen((event) {
      _user = event;
      loadSubjects();
      update();
    }, 'user');
    loadSubjects();
    _internetStatusSubscription = InternetConnection().onStatusChange.listen((
      event,
    ) {
      if (event == InternetStatus.connected) {
        loadSubjects();
      }
    });
  }

  void loadSubjects() async {
    _isLoading = true;
    update();

    try {
      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      _subjects = await SubjectsService().getSubjects(
        device.id,
        gradeId: _user?.grade.id ?? 0,
      );
      await HiveSubjectsStorage().write('subjects', _subjects);
    } catch (e) {
      _subjects = await HiveSubjectsStorage().read('subjects');
    } finally {
      _isLoading = false;
      update();
    }
  }

  void navigateToSubjectDetail(int subjectId) {
    // Navigate to subject detail page for the selected subject
    Get.to(() => SubjectDetail(), arguments: {'subjectId': subjectId});
  }

  bool isSubjectLocked(Subject subject) {
    return subject.isLocked && !hasFullAccessOverride;
  }

  @override
  void dispose() {
    _internetStatusSubscription.cancel();
    super.dispose();
  }
}
