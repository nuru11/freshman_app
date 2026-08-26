import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/premium_service.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PomodoroNotificationSlot {
  const PomodoroNotificationSlot({
    required this.at,
    required this.title,
    required this.body,
    required this.phase,
  });

  final DateTime at;
  final String title;
  final String body;
  final String phase;
}

/// Local Notification Service for handling local notifications using awesome_notifications
class LocalNotificationService extends GetxService {
  static const String channelKey = 'study_plans_channel';
  static const String silentChannelKey = 'study_plans_channel_silent_high';
  static const String alarmChannelKey = 'study_plans_channel_alarm';
  static const String channelName = 'Study Plans';
  static const String channelDescription = 'Notifications for your study plans';
  static const String pomodoroChannelKey = 'pomodoro_channel';
  static const String challengeChannelKey = 'challenge_channel';

  static const int _planIdBase = 200000;
  static const int _pomodoroAlarmIdBase = 900010;
  static const int _pomodoroAlarmCount = 16;
  static const int _challengeStartIdBase = 800000;
  static const int _challengeEndIdBase = 830000;
  static const int _challengeDailyIdBase = 860000;

  static bool _pluginInitialized = false;

  @override
  void onInit() {
    super.onInit();
    initializePlugin();
  }

  /// Call from app startup and await before [runApp].
  static Future<void> initializePlugin() async {
    if (_pluginInitialized) return;
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
          channelKey: alarmChannelKey,
          channelName: 'Study Plan Alarms',
          channelDescription: 'Alarm-style reminders for study plans',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelKey: silentChannelKey,
          channelName: 'Study Plan Silent Reminders',
          channelDescription: 'Silent reminders for study plans',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          playSound: false,
          enableVibration: false,
          enableLights: false,
          channelShowBadge: true,
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
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelKey: challengeChannelKey,
          channelName: 'Reading Challenges',
          channelDescription: 'Start, end, and daily reminders for reading challenges',
          defaultColor: const Color(0xFFC48A1A),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
          criticalAlerts: true,
        ),
      ],
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onNotificationDismissed,
    );
    _pluginInitialized = true;
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

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) return true;

      final result = await Permission.scheduleExactAlarm.request();
      if (result.isGranted) {
        logger.i('Exact alarm permission granted');
        return true;
      }
      logger.w('Exact alarm permission denied');
      return false;
    } catch (e) {
      logger.e('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  Future<bool> isExactAlarmGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      logger.w('Could not read exact alarm permission: $e');
      return false;
    }
  }

  Future<bool> isBatteryUnrestricted() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (e) {
      logger.w('Could not read battery optimization status: $e');
      return true;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      if (await Permission.ignoreBatteryOptimizations.isGranted) return true;
      final result = await Permission.ignoreBatteryOptimizations.request();
      return result.isGranted;
    } catch (e) {
      logger.e('Error requesting ignore battery optimizations: $e');
      return false;
    }
  }

  Future<bool> _shouldUsePreciseAlarm() async {
    if (!Platform.isAndroid) return true;
    return isExactAlarmGranted();
  }

  Future<bool> isNotificationAllowed() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      logger.e('Error checking notification permission: $e');
      return false;
    }
  }

  bool _isLoudPlan(StudyPlan plan) {
    try {
      return Get.find<PremiumService>().isPremium && plan.alarmsEnabled;
    } catch (_) {
      return false;
    }
  }

  String _channelForPlan({required bool loud}) {
    return loud ? alarmChannelKey : silentChannelKey;
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

      final loud = _isLoudPlan(plan);
      final alarms = loud
          ? (plan.alarms.isEmpty
              ? [StudyPlanAlarm.defaultAlarm()]
              : plan.alarms.where((a) => a.enabled).toList())
          : [StudyPlanAlarm.defaultAlarm()];
      if (alarms.isEmpty) return;

      for (var i = 0; i < alarms.length; i++) {
        final alarm = alarms[i];
        if (plan.isRepeating && plan.repeatDays.isNotEmpty) {
          await _scheduleRepeatingAlarm(plan, alarm, i, loud: loud);
        } else {
          await _scheduleOneTimeAlarm(plan, alarm, i, loud: loud);
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
    int alarmIndex, {
    required bool loud,
  }) async {
    final realFire = plan.nextNotificationAt(alarm: alarm, alarmsOn: true);
    if (realFire == null) return;
    await _createPlanAlarmNotification(
      plan: plan,
      alarm: alarm,
      id: _notificationId(plan.id, alarmIndex),
      deviceFire: AppClock.toDeviceTime(realFire),
      loud: loud,
    );
  }

  Future<void> _scheduleRepeatingAlarm(
    StudyPlan plan,
    StudyPlanAlarm alarm,
    int alarmIndex, {
    required bool loud,
  }) async {
    final start = plan.startDate?.toLocal();
    if (start == null) return;

    var minute = start.minute - alarm.offsetMinutes;
    var hour = start.hour;
    while (minute < 0) {
      minute += 60;
      hour -= 1;
    }
    if (hour < 0) hour += 24;

    final preciseAlarm = await _shouldUsePreciseAlarm();
    final realNow = AppClock.now();
    for (final dayOfWeek in plan.repeatDays) {
      var day = DateTime(realNow.year, realNow.month, realNow.day);
      while (day.weekday != dayOfWeek) {
        day = day.add(const Duration(days: 1));
      }
      final realFire = DateTime(day.year, day.month, day.day, hour, minute);
      final deviceFire = AppClock.toDeviceTime(realFire);
      await AwesomeNotifications().createNotification(
        content: _planAlarmContent(
          id: _notificationId(plan.id, alarmIndex, dayOfWeek),
          plan: plan,
          alarm: alarm,
          loud: loud,
          extraPayload: {'day_of_week': dayOfWeek.toString()},
        ),
        actionButtons: [
          NotificationActionButton(key: 'SNOOZE', label: 'Snooze'),
        ],
        schedule: NotificationCalendar(
          hour: deviceFire.hour,
          minute: deviceFire.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: preciseAlarm,
          weekday: deviceFire.weekday,
        ),
      );
    }

    final nextReal = plan.nextNotificationAt(alarm: alarm, alarmsOn: true);
    if (nextReal != null) {
      final until = nextReal.difference(realNow);
      final isGraceFire =
          nextReal.hour != hour || nextReal.minute != minute;
      if (until <= const Duration(minutes: 3) && isGraceFire) {
        await _createPlanAlarmNotification(
          plan: plan,
          alarm: alarm,
          id: _notificationId(plan.id, alarmIndex),
          deviceFire: AppClock.toDeviceTime(nextReal),
          preciseAlarm: preciseAlarm,
          loud: loud,
        );
      }
    }
  }

  NotificationContent _planAlarmContent({
    required int id,
    required StudyPlan plan,
    required StudyPlanAlarm alarm,
    required bool loud,
    Map<String, String> extraPayload = const {},
  }) {
    return NotificationContent(
      id: id,
      channelKey: _channelForPlan(loud: loud),
      title: 'Study Plan Reminder',
      body:
          '${plan.title}${plan.subject.isNotEmpty ? ' - ${plan.subject}' : ''}',
      notificationLayout: NotificationLayout.Default,
      category: loud ? NotificationCategory.Alarm : NotificationCategory.Reminder,
      wakeUpScreen: loud,
      fullScreenIntent: loud,
      autoDismissible: !loud,
      payload: {
        'plan_id': plan.id.toString(),
        'snooze_minutes': alarm.snoozeMinutes.toString(),
        'sound': alarm.sound,
        'vibration': alarm.vibration,
        'loud': loud ? 'true' : 'false',
        ...extraPayload,
      },
    );
  }

  Future<void> _createPlanAlarmNotification({
    required StudyPlan plan,
    required StudyPlanAlarm alarm,
    required int id,
    required DateTime deviceFire,
    required bool loud,
    bool? preciseAlarm,
  }) async {
    final precise = preciseAlarm ?? await _shouldUsePreciseAlarm();
    await AwesomeNotifications().createNotification(
      content: _planAlarmContent(
        id: id,
        plan: plan,
        alarm: alarm,
        loud: loud,
      ),
      actionButtons: [
        NotificationActionButton(key: 'SNOOZE', label: 'Snooze'),
      ],
      schedule: NotificationCalendar.fromDate(
        date: deviceFire,
        allowWhileIdle: true,
        preciseAlarm: precise,
      ),
    );
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

  Future<void> schedulePomodoroCycle(List<PomodoroNotificationSlot> alarms) async {
    await cancelPomodoroNotifications();
    final preciseAlarm = await _shouldUsePreciseAlarm();
    final now = DateTime.now();
    final count = alarms.length < _pomodoroAlarmCount
        ? alarms.length
        : _pomodoroAlarmCount;
    for (var i = 0; i < count; i++) {
      final alarm = alarms[i];
      if (!alarm.at.isAfter(now)) continue;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _pomodoroAlarmIdBase + i,
          channelKey: pomodoroChannelKey,
          title: alarm.title,
          body: alarm.body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          payload: {'type': 'pomodoro', 'phase': alarm.phase},
        ),
        schedule: NotificationCalendar.fromDate(
          date: alarm.at,
          allowWhileIdle: true,
          preciseAlarm: preciseAlarm,
        ),
      );
    }
  }

  Future<void> cancelPomodoroNotifications() async {
    await AwesomeNotifications().cancel(900001);
    await AwesomeNotifications().cancel(900002);
    for (var i = 0; i < _pomodoroAlarmCount; i++) {
      await AwesomeNotifications().cancel(_pomodoroAlarmIdBase + i);
    }
  }

  Future<void> scheduleChallengeWindowAlarms({
    required int challengeId,
    required String title,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    await cancelChallengeWindowAlarms(challengeId);
    final preciseAlarm = await _shouldUsePreciseAlarm();
    final now = AppClock.now();
    if (startAt != null) {
      await _createChallengeAlarm(
        id: _challengeStartIdBase + challengeId,
        title: 'Challenge started: $title',
        body: 'Your reading challenge has started. Time to read.',
        type: 'challenge_start',
        challengeId: challengeId,
        realFire: startAt,
        now: now,
        preciseAlarm: preciseAlarm,
      );
    }
    if (endAt != null) {
      await _createChallengeAlarm(
        id: _challengeEndIdBase + challengeId,
        title: 'Challenge ended: $title',
        body: 'The reading challenge has ended.',
        type: 'challenge_end',
        challengeId: challengeId,
        realFire: endAt,
        now: now,
        preciseAlarm: preciseAlarm,
      );
    }
  }

  Future<void> cancelChallengeWindowAlarms(int challengeId) async {
    await AwesomeNotifications().cancel(_challengeStartIdBase + challengeId);
    await AwesomeNotifications().cancel(_challengeEndIdBase + challengeId);
  }

  Future<void> scheduleChallengeDailyReminder({
    required int challengeId,
    required String title,
    int hour = 8,
    int minute = 0,
  }) async {
    await cancelChallengeReminder(challengeId);
    final preciseAlarm = await _shouldUsePreciseAlarm();
    final realNow = AppClock.now();
    var realFire = DateTime(
      realNow.year,
      realNow.month,
      realNow.day,
      hour,
      minute,
    );
    if (!realFire.isAfter(realNow)) {
      realFire = realFire.add(const Duration(days: 1));
    }
    final deviceFire = AppClock.toDeviceTime(realFire);
    await AwesomeNotifications().createNotification(
      content: _challengeAlarmContent(
        id: _challengeDailyIdBase + challengeId,
        title: 'Reading challenge',
        body: 'Time to read: $title',
        type: 'challenge',
        challengeId: challengeId,
      ),
      actionButtons: [
        NotificationActionButton(key: 'SNOOZE', label: 'Snooze'),
      ],
      schedule: NotificationCalendar(
        hour: deviceFire.hour,
        minute: deviceFire.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: preciseAlarm,
      ),
    );
  }

  Future<void> cancelChallengeReminder(int challengeId) async {
    await AwesomeNotifications().cancel(_challengeDailyIdBase + challengeId);
  }

  NotificationContent _challengeAlarmContent({
    required int id,
    required String title,
    required String body,
    required String type,
    required int challengeId,
  }) {
    return NotificationContent(
      id: id,
      channelKey: challengeChannelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
      category: NotificationCategory.Alarm,
      wakeUpScreen: true,
      fullScreenIntent: true,
      autoDismissible: false,
      payload: {
        'type': type,
        'challenge_id': challengeId.toString(),
        'loud': 'true',
        'snooze_minutes': '5',
        'channel': challengeChannelKey,
      },
    );
  }

  Future<void> _createChallengeAlarm({
    required int id,
    required String title,
    required String body,
    required String type,
    required int challengeId,
    required DateTime realFire,
    required DateTime now,
    required bool preciseAlarm,
  }) async {
    final fireAt = AppClock.applyNotifyGrace(realFire, now) ??
        (realFire.isAfter(now) ? realFire : null);
    if (fireAt == null) return;
    await AwesomeNotifications().createNotification(
      content: _challengeAlarmContent(
        id: id,
        title: title,
        body: body,
        type: type,
        challengeId: challengeId,
      ),
      actionButtons: [
        NotificationActionButton(key: 'SNOOZE', label: 'Snooze'),
      ],
      schedule: NotificationCalendar.fromDate(
        date: AppClock.toDeviceTime(fireAt),
        allowWhileIdle: true,
        preciseAlarm: preciseAlarm,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationActionReceived(
    ReceivedAction receivedAction,
  ) async {
    logger.d('Notification action received: ${receivedAction.id}');
    if (receivedAction.buttonKeyPressed == 'SNOOZE') {
      final minutes =
          int.tryParse(receivedAction.payload?['snooze_minutes'] ?? '5') ?? 5;
      final loud = receivedAction.payload?['loud'] == 'true';
      final snoozeChannel = receivedAction.payload?['channel'] ??
          (loud ? alarmChannelKey : silentChannelKey);
      final snoozeId = 910000 + (receivedAction.id ?? 0) % 1000;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: snoozeId,
          channelKey: snoozeChannel,
          title: receivedAction.title ?? 'Study Plan Reminder',
          body: receivedAction.body ?? 'Snoozed reminder',
          category: loud
              ? NotificationCategory.Alarm
              : NotificationCategory.Reminder,
          wakeUpScreen: loud,
          fullScreenIntent: loud,
          autoDismissible: !loud,
        ),
        schedule: NotificationCalendar.fromDate(
          date: DateTime.now().add(Duration(minutes: minutes)),
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreated(
    ReceivedNotification receivedNotification,
  ) async {
    logger.d('Notification created: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
    ReceivedNotification receivedNotification,
  ) async {
    logger.d('Notification displayed: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDismissed(
    ReceivedAction receivedAction,
  ) async {
    logger.d('Notification dismissed: ${receivedAction.id}');
  }
}
