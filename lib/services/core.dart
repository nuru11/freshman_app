import 'package:get/get.dart';
import 'auth.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/misc.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'dart:async';

class CoreService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final HiveSubjectsStorage subjectsStorage = HiveSubjectsStorage();
  final HiveChaptersStorage chaptersStorage = HiveChaptersStorage();

  RxList<Subject> subjects = <Subject>[].obs;

  late StreamSubscription<InternetStatus> internetStatusSubscription;

  bool hasInternet = false;

  Future<void> loadSubjects() async {
    subjects.value = await subjectsStorage.read('subjects');
  }

  Future<void> setSubjects(List<Subject> subjects) async {
    this.subjects.value = subjects;
    return subjectsStorage.write('subjects', subjects);
  }

  @override
  void onClose() {
    internetStatusSubscription.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    loadSubjects();

    internetStatusSubscription = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      switch (status) {
        case InternetStatus.connected:
          // The internet is now connected
          hasInternet = true;
          break;
        case InternetStatus.disconnected:
          // The internet is now disconnected
          hasInternet = false;
          break;
      }
    });
  }
}
