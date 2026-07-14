import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:vector_academy/utils/storages/app_header.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:vector_academy/services/auth.dart';
import 'package:vector_academy/services/core.dart';
import 'package:vector_academy/services/api/grades.dart';
import 'package:vector_academy/services/notification_service.dart'
    as local_notif;
import 'package:flutter_tex/flutter_tex.dart';

Future<void> initialize() async {
  await TeXRenderingServer.start();
  await Hive.initFlutter();
  await HiveChaptersStorage().init();
  await HiveSubjectsStorage().init();
  await HiveAuthStorage().init();
  await HiveUserStorage().init();
  await HiveExamStorage().init();
  await HiveQuizzesStorage().init();
  await HiveNoteStorage().init();
  await HiveVideoStorage().init();
  await HiveStudyPlanStorage().init();
  await HiveAppHeaderStorage().init();
  await HiveNewsStorage().init();
  await HiveLeaderboardCacheStorage().init();
  Get.put(AuthService());
  Get.put(CoreService());
  Get.put(GradeService());

  await ConfigPreference.init();

  // Register notification service (permissions requested in-context from Study Planner)
  Get.put(local_notif.LocalNotificationService());

  final authToken = await HiveAuthStorage().getAuthToken();

  BaseApiClient.setTokens(authToken?.access ?? '', authToken?.refresh ?? '');

  logger.i('Initilizing The application');
}
