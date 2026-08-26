import 'package:get/get.dart';
import 'package:vector_academy/models/reading_premium.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/api/reading_challenge.dart';
import 'package:vector_academy/services/auth.dart';
import 'package:vector_academy/services/notification_service.dart';
import 'package:vector_academy/services/premium_service.dart';
import 'package:vector_academy/utils/snackbar_utils.dart';
import 'package:vector_academy/utils/study_planner_reminder_permissions.dart';
import 'package:vector_academy/utils/utils.dart';

class ChallengeController extends GetxController {
  final ReadingChallengeService _service = Get.find<ReadingChallengeService>();

  bool isLoading = false;
  List<ReadingChallenge> challenges = [];

  bool get _canLoadPremiumContent {
    if (!Get.isRegistered<AuthService>() ||
        !Get.find<AuthService>().isAuthenticated) {
      return false;
    }
    if (!Get.isRegistered<PremiumService>()) return false;
    return Get.find<PremiumService>().isPremium;
  }

  @override
  void onInit() {
    super.onInit();
    load(showError: false);
  }

  Future<void> load({bool showError = true}) async {
    if (!_canLoadPremiumContent) {
      challenges = [];
      isLoading = false;
      update();
      return;
    }

    isLoading = true;
    update();
    try {
      challenges = await _service.listChallenges();
      try {
        await _rescheduleJoinedAlarms();
      } catch (e) {
        logger.e('Failed to reschedule challenge alarms: $e');
      }
    } catch (e) {
      logger.e('Failed to load challenges: $e');
      if (showError) {
        AppSnackbar.showError(
          'Error',
          e is ApiException ? e.message : 'Failed to load challenges',
        );
      }
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> join(ReadingChallenge challenge) async {
    try {
      await StudyPlannerReminderPermissions.ensureBeforeScheduling();
      final updated = await _service.join(challenge.id);
      _replace(updated);
      await _scheduleWindowAlarms(updated);
      AppSnackbar.showSuccess('Joined', 'You joined ${challenge.title}');
    } catch (e) {
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to join',
      );
    }
  }

  Future<void> toggleAlarm(ReadingChallenge challenge, bool enabled) async {
    if (!challenge.joined) {
      AppSnackbar.showWarning('Join first', 'Join the challenge to set an alarm');
      return;
    }
    if (enabled) {
      await StudyPlannerReminderPermissions.ensureBeforeScheduling();
    }
    try {
      final updated = await _service.setAlarm(challenge.id, enabled);
      _replace(updated);
      final notifications = Get.find<LocalNotificationService>();
      if (enabled) {
        await notifications.scheduleChallengeDailyReminder(
          challengeId: challenge.id,
          title: challenge.title,
          hour: ReadingChallenge.dailyAlarmHour,
          minute: ReadingChallenge.dailyAlarmMinute,
        );
      } else {
        await notifications.cancelChallengeReminder(challenge.id);
      }
    } catch (e) {
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to update alarm',
      );
    }
  }

  Future<void> _rescheduleJoinedAlarms() async {
    final notifications = Get.find<LocalNotificationService>();
    for (final challenge in challenges) {
      if (!challenge.joined) continue;
      await _scheduleWindowAlarms(challenge);
      if (challenge.alarmEnabled) {
        await notifications.scheduleChallengeDailyReminder(
          challengeId: challenge.id,
          title: challenge.title,
          hour: ReadingChallenge.dailyAlarmHour,
          minute: ReadingChallenge.dailyAlarmMinute,
        );
      }
    }
  }

  Future<void> _scheduleWindowAlarms(ReadingChallenge challenge) async {
    await Get.find<LocalNotificationService>().scheduleChallengeWindowAlarms(
      challengeId: challenge.id,
      title: challenge.title,
      startAt: challenge.startAt,
      endAt: challenge.deadline,
    );
  }

  void _replace(ReadingChallenge updated) {
    final index = challenges.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      challenges[index] = updated;
      update();
    }
  }
}
