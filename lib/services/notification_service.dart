import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Local Notification Service for handling local notifications using awesome_notifications
class LocalNotificationService extends GetxService {
  static const String channelKey = 'study_plans_channel';
  static const String channelName = 'Study Plans';
  static const String channelDescription = 'Notifications for your study plans';
  static const String pomodoroChannelKey = 'pomodoro_channel';
  static const String challengeChannelKey = 'challenge_channel';

  static const int _planIdBase = 200000;
  static const int _pomodoroWorkId = 900001;
  static const int _pomodoroGapId = 900002;
  static const int _challengeIdBase = 800000;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  /// Initialize awesome notifications
  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: channelName,
          channelDescription: channelDescription,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
        NotificationChannel(
          channelKey: '${channelKey}_alarm',
          channelName: 'Study Plan Alarms',
          channelDescription: 'Alarm-style reminders for study plans',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        ),
        NotificationChannel(
          channelKey: pomodoroChannelKey,
          channelName: 'Pomodoro',
          channelDescription: 'Pomodoro work and break alerts',
          defaultColor: const Color(0xFF0B5F56),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        ),
        NotificationChannel(
          channelKey: challengeChannelKey,
          channelName: 'Reading Challenges',
          channelDescription: 'Daily reminders for reading challenges',
          defaultColor: const Color(0xFFC48A1A),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
      ],
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onNotificationDismissed,
    );
  }

  Future<bool> ensureNotificationPermission() async {
    try {
      final isAllowed = await AwesomeNotifications()
          .requestPermissionToSendNotifications();

      if (!isAllowed) {
        logger.w('Notification permission denied');
      } else {
        logger.i('Notification permissions granted');
      }
      return isAllowed;
    } catch (e) {
      logger.e('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.scheduleExactAlarm.status;

      if (status.isGranted) {
        logger.i('Exact alarm permission already granted');
        return;
      }

      if (status.isDenied || status.isLimited) {
        final result = await Permission.scheduleExactAlarm.request();
        if (result.isGranted) {
          logger.i('Exact alarm permission granted');
        } else {
          logger.w('Exact alarm permission denied');
        }
      }
    } catch (e) {
      logger.e('Error requesting exact alarm permission: $e');
    }
  }

  Future<bool> _shouldUsePreciseAlarm() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      logger.w('Could not read exact alarm permission: $e');
      return false;
    }
  }

  Future<bool> isNotificationAllowed() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      logger.e('Error checking notification permission: $e');
      return false;
    }
  }

  String _channelForSound(String sound) {
    if (sound == 'alarm') return '${channelKey}_alarm';
    return channelKey;
  }

  int _notificationId(int planId, int alarmIndex, [int weekday = 0]) {
    return _planIdBase + planId * 80 + alarmIndex * 8 + weekday;
  }

  Future<void> scheduleStudyPlanNotification(StudyPlan plan) async {
    try {
      await cancelStudyPlanNotifications(plan.id);

      if (plan.startDate == null) {
        logger.d('Plan ${plan.id} has no date, skipping notification');
        return;
      }

      if (!plan.alarmsEnabled) {
        logger.d('Plan ${plan.id} alarms disabled');
        return;
      }

      final alarms = plan.alarms.isEmpty
          ? [StudyPlanAlarm.defaultAlarm()]
          : plan.alarms.where((a) => a.enabled).toList();
      if (alarms.isEmpty) return;

      for (var i = 0; i < alarms.length; i++) {
        final alarm = alarms[i];
        if (plan.isRepeating && plan.repeatDays.isNotEmpty) {
          await _scheduleRepeatingAlarm(plan, alarm, i);
        } else {
          await _scheduleOneTimeAlarm(plan, alarm, i);
        }
      }

      logger.i('Scheduled notification for study plan: ${plan.id}');
    } catch (e) {
      logger.e('Error scheduling notification for plan ${plan.id}: $e');
    }
  }

  Future<void> _scheduleOneTimeAlarm(
    StudyPlan plan,
    StudyPlanAlarm alarm,
    int alarmIndex,
  ) async {
    final notificationDate = plan.dueDate ?? plan.startDate ?? plan.endDate;
    if (notificationDate == null) return;
    final scheduled = notificationDate.subtract(
      Duration(minutes: alarm.offsetMinutes),
    );
    if (scheduled.isBefore(DateTime.now())) return;

    final preciseAlarm = await _shouldUsePreciseAlarm();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _notificationId(plan.id, alarmIndex),
        channelKey: _channelForSound(alarm.sound),
        title: 'Study Plan Reminder',
        body:
            '${plan.title}${plan.subject.isNotEmpty ? ' - ${plan.subject}' : ''}',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        payload: {
          'plan_id': plan.id.toString(),
          'snooze_minutes': alarm.snoozeMinutes.toString(),
          'sound': alarm.sound,
          'vibration': alarm.vibration,
        },
      ),
      actionButtons: [
        NotificationActionButton(key: 'SNOOZE', label: 'Snooze'),
      ],
      schedule: NotificationCalendar.fromDate(
        date: scheduled,
        allowWhileIdle: true,
        preciseAlarm: preciseAlarm,
      ),
    );
  }

  Future<void> _scheduleRepeatingAlarm(
    StudyPlan plan,
    StudyPlanAlarm alarm,
    int alarmIndex,
  ) async {
    final start = plan.startDate;
    if (start == null) return;

    var minute = start.minute - alarm.offsetMinutes;
    var hour = start.hour;
    while (minute < 0) {
      minute += 60;
      hour -= 1;
    }
    if (hour < 0) hour += 24;

    final preciseAlarm = await _shouldUsePreciseAlarm();
    for (final dayOfWeek in plan.repeatDays) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _notificationId(plan.id, alarmIndex, dayOfWeek),
          channelKey: _channelForSound(alarm.sound),
          title: 'Study Plan Reminder',
          body:
              '${plan.title}${plan.subject.isNotEmpty ? ' - ${plan.subject}' : ''}',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          payload: {
            'plan_id': plan.id.toString(),
            'day_of_week': dayOfWeek.toString(),
            'snooze_minutes': alarm.snoozeMinutes.toString(),
            'sound': alarm.sound,
            'vibration': alarm.vibration,
          },
        ),
        actionButtons: [
          NotificationActionButton(key: 'SNOOZE', label: 'Snooze'),
        ],
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: preciseAlarm,
          weekday: dayOfWeek,
        ),
      );
    }
  }

  Future<void> cancelStudyPlanNotifications(int planId) async {
    try {
      await AwesomeNotifications().cancel(planId);
      for (int day = 1; day <= 7; day++) {
        await AwesomeNotifications().cancel(planId * 10 + day);
      }
      for (var alarmIndex = 0; alarmIndex < 10; alarmIndex++) {
        for (var weekday = 0; weekday <= 7; weekday++) {
          await AwesomeNotifications().cancel(
            _notificationId(planId, alarmIndex, weekday),
          );
        }
      }
      logger.d('Cancelled notifications for plan: $planId');
    } catch (e) {
      logger.e('Error cancelling notifications for plan $planId: $e');
    }
  }

  Future<void> scheduleAllStudyPlans(List<StudyPlan> plans) async {
    final isAllowed = await isNotificationAllowed();
    if (!isAllowed) {
      logger.w('Notifications not allowed, skipping scheduling');
      return;
    }

    for (final plan in plans) {
      await scheduleStudyPlanNotification(plan);
    }

    logger.i('Scheduled notifications for ${plans.length} study plans');
  }

  Future<void> cancelAllStudyPlanNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      logger.i('Cancelled all study plan notifications');
    } catch (e) {
      logger.e('Error cancelling all notifications: $e');
    }
  }

  Future<void> schedulePomodoroEnd({
    required DateTime at,
    required bool isWorkPhase,
  }) async {
    await cancelPomodoroNotifications();
    if (at.isBefore(DateTime.now())) return;
    final preciseAlarm = await _shouldUsePreciseAlarm();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: isWorkPhase ? _pomodoroWorkId : _pomodoroGapId,
        channelKey: pomodoroChannelKey,
        title: isWorkPhase ? 'Work session complete' : 'Gap complete',
        body: isWorkPhase
            ? 'Time for a 40-minute gap.'
            : 'Back to 25 minutes of work.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        payload: {'type': 'pomodoro', 'phase': isWorkPhase ? 'work' : 'gap'},
      ),
      schedule: NotificationCalendar.fromDate(
        date: at,
        allowWhileIdle: true,
        preciseAlarm: preciseAlarm,
      ),
    );
  }

  Future<void> cancelPomodoroNotifications() async {
    await AwesomeNotifications().cancel(_pomodoroWorkId);
    await AwesomeNotifications().cancel(_pomodoroGapId);
  }

  Future<void> scheduleChallengeDailyReminder({
    required int challengeId,
    required String title,
    int hour = 8,
    int minute = 0,
  }) async {
    await cancelChallengeReminder(challengeId);
    final preciseAlarm = await _shouldUsePreciseAlarm();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _challengeIdBase + challengeId,
        channelKey: challengeChannelKey,
        title: 'Reading challenge',
        body: 'Time to read: $title',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        payload: {'type': 'challenge', 'challenge_id': challengeId.toString()},
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: preciseAlarm,
      ),
    );
  }

  Future<void> cancelChallengeReminder(int challengeId) async {
    await AwesomeNotifications().cancel(_challengeIdBase + challengeId);
  }

  static Future<void> _onNotificationActionReceived(
    ReceivedAction receivedAction,
  ) async {
    logger.d('Notification action received: ${receivedAction.id}');
    if (receivedAction.buttonKeyPressed == 'SNOOZE') {
      final minutes =
          int.tryParse(receivedAction.payload?['snooze_minutes'] ?? '5') ?? 5;
      final sound = receivedAction.payload?['sound'] ?? 'default';
      final snoozeId = 910000 + (receivedAction.id ?? 0) % 1000;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: snoozeId,
          channelKey: sound == 'alarm' ? '${channelKey}_alarm' : channelKey,
          title: receivedAction.title ?? 'Study Plan Reminder',
          body: receivedAction.body ?? 'Snoozed reminder',
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar.fromDate(
          date: DateTime.now().add(Duration(minutes: minutes)),
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    }
  }

  static Future<void> _onNotificationCreated(
    ReceivedNotification receivedNotification,
  ) async {
    logger.d('Notification created: ${receivedNotification.id}');
  }

  static Future<void> _onNotificationDisplayed(
    ReceivedNotification receivedNotification,
  ) async {
    logger.d('Notification displayed: ${receivedNotification.id}');
  }

  static Future<void> _onNotificationDismissed(
    ReceivedAction receivedAction,
  ) async {
    logger.d('Notification dismissed: ${receivedAction.id}');
  }
}
