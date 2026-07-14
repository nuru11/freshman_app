import 'package:get/get.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'dart:async';
import 'package:vector_academy/utils/storages/storages.dart';

class SubjectDetailController extends GetxController {
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool isLocked = true;
  Subject? _subject;
  Subject? get subject => _subject;

  String _subjectName = '';
  String get subjectName => _subjectName;

  List<Chapter> _chapters = [];
  List<Chapter> get chapters => _chapters;
  int? _freePreviewChapterId;

  int subjectId = 0;
  // ignore: unused_field
  User? _user;
  bool get _hasFullAccessOverride =>
      hasFullAccessOverrideForPhone(_user?.phoneNumber);
  late StreamSubscription<InternetStatus> _internetStatusSubscription;

  @override
  void onInit() async {
    super.onInit();
    subjectId = Get.arguments?['subjectId'] ?? 1;
    _user = await HiveUserStorage().getUser();
    loadSubjectDetail();
    _internetStatusSubscription = InternetConnection().onStatusChange.listen((
      event,
    ) {
      if (event == InternetStatus.connected) {
        loadSubjectDetail();
      }
    });
  }

  void loadSubjectDetail() async {
    _isLoading = true;
    update();
    try {
      _subject = (await HiveSubjectsStorage().read(
        'subjects',
      )).firstWhere((element) => element.id == subjectId);
      logger.i('subject: $_subject ${_subject?.isLocked}');

      isLocked = (_subject?.isLocked ?? true) && !_hasFullAccessOverride;

      _subjectName = _subject?.name ?? '';
      _chapters = _subject?.chapters ?? [];
      _chapters.sort((e1, e2) => e1.chapterNumber.compareTo(e2.chapterNumber));
      _freePreviewChapterId = _chapters.isNotEmpty ? _chapters.first.id : null;
    } catch (e) {
      logger.e(e);
      Get.snackbar('Error', 'Failed to load subject details');
      rethrow;
    } finally {
      _isLoading = false;
      update();
    }
  }

  bool isPreviewChapter(Chapter chapter) => chapter.id == _freePreviewChapterId;

  bool isChapterLocked(Chapter chapter) => isLocked && !isPreviewChapter(chapter);

  void handleChapterTap(Chapter chapter) {
    if (isChapterLocked(chapter)) {
      Get.toNamed(
        VIEWS.payments.path,
        arguments: {'subjectId': subjectId, 'subjectName': _subjectName},
      );
      Get.snackbar(
        'Subscription Required',
        'Pay once to unlock all chapters in $_subjectName.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    openChapter(chapter.id);
  }

  void openChapter(int chapterId) {
    Get.toNamed(
      VIEWS.chapterDetail.path,
      arguments: {'chapterId': chapterId, 'subjectId': subjectId},
    );
  }

  @override
  void onClose() {
    _internetStatusSubscription.cancel();
    super.onClose();
  }
}
