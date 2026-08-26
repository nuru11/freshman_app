import 'package:get/get.dart';
import 'package:vector_academy/controllers/exam/exam_controller.dart';
import 'package:vector_academy/controllers/home/home_dashboard_controller.dart';
import 'package:vector_academy/controllers/home/main_navigation_controller.dart';
import 'package:vector_academy/controllers/leaderboard/leaderboard_controller.dart';
import 'package:vector_academy/controllers/misc/downloads_controller.dart';
import 'package:vector_academy/controllers/misc/news_controller.dart';
import 'package:vector_academy/controllers/misc/profile_controller.dart';
import 'package:vector_academy/controllers/misc/user_score_controller.dart';
import 'package:vector_academy/controllers/study_hub/challenge_controller.dart';
import 'package:vector_academy/controllers/study_hub/pomodoro_controller.dart';
import 'package:vector_academy/controllers/study_hub/reading_plan_controller.dart';
import 'package:vector_academy/controllers/study_hub/study_hub_controller.dart';
import 'package:vector_academy/controllers/study_planner/study_planner_controller.dart';
import 'package:vector_academy/services/api/reading_challenge.dart';
import 'package:vector_academy/services/api/reading_plan.dart';
import 'package:vector_academy/services/api/study_planner.dart';
import 'package:vector_academy/services/pomodoro_service.dart';
import 'package:vector_academy/services/premium_service.dart';

void clearHomeTabControllers() {
  if (Get.isRegistered<HomeDashboardController>()) {
    Get.delete<HomeDashboardController>(force: true);
  }
  if (Get.isRegistered<MainNavigationController>()) {
    Get.delete<MainNavigationController>(force: true);
  }
  if (Get.isRegistered<ProfileController>()) {
    Get.delete<ProfileController>(force: true);
  }
  if (Get.isRegistered<ExamController>()) {
    Get.delete<ExamController>(force: true);
  }
  if (Get.isRegistered<NewsController>()) {
    Get.delete<NewsController>(force: true);
  }
  if (Get.isRegistered<DownloadsController>()) {
    Get.delete<DownloadsController>(force: true);
  }
  if (Get.isRegistered<LeaderboardController>()) {
    Get.delete<LeaderboardController>(force: true);
  }
  if (Get.isRegistered<UserScoreController>()) {
    Get.delete<UserScoreController>(force: true);
  }
  if (Get.isRegistered<StudyPlannerService>()) {
    Get.delete<StudyPlannerService>(force: true);
  }
  if (Get.isRegistered<StudyPlannerController>()) {
    Get.delete<StudyPlannerController>(force: true);
  }
  if (Get.isRegistered<PremiumService>()) {
    Get.delete<PremiumService>(force: true);
  }
  if (Get.isRegistered<StudyHubController>()) {
    Get.delete<StudyHubController>(force: true);
  }
  if (Get.isRegistered<PomodoroService>()) {
    Get.delete<PomodoroService>(force: true);
  }
  if (Get.isRegistered<PomodoroController>()) {
    Get.delete<PomodoroController>(force: true);
  }
  if (Get.isRegistered<ReadingPlanService>()) {
    Get.delete<ReadingPlanService>(force: true);
  }
  if (Get.isRegistered<ReadingPlanController>()) {
    Get.delete<ReadingPlanController>(force: true);
  }
  if (Get.isRegistered<ReadingChallengeService>()) {
    Get.delete<ReadingChallengeService>(force: true);
  }
  if (Get.isRegistered<ChallengeController>()) {
    Get.delete<ChallengeController>(force: true);
  }
}
