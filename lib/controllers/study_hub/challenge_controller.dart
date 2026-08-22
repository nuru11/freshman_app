import 'package:get/get.dart';
import 'package:vector_academy/models/reading_premium.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/api/reading_challenge.dart';
import 'package:vector_academy/services/notification_service.dart';
import 'package:vector_academy/utils/snackbar_utils.dart';
import 'package:vector_academy/utils/study_planner_reminder_permissions.dart';
import 'package:vector_academy/utils/utils.dart';

class ChallengeController extends GetxController {
  final ReadingChallengeService _service = Get.find<ReadingChallengeService>();

  bool isLoading = false;
  List<ReadingChallenge> challenges = [];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading = true;
    update();
    try {
      challenges = await _service.listChallenges();
    } catch (e) {
      logger.e('Failed to load challenges: $e');
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to load challenges',
      );
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> join(ReadingChallenge challenge) async {
    try {
      final updated = await _service.join(challenge.id);
      _replace(updated);
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

  void _replace(ReadingChallenge updated) {
    final index = challenges.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      challenges[index] = updated;
      update();
    }
  }
}
