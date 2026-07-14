import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

class ConfigPreference {
  // Prevent instantiation
  ConfigPreference._();

  static const String _preferencesBox = 'preferences';
  static const String _currentLocalKey = 'current_local';
  static const String _lightThemeKey = 'is_theme_light';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _accessTokenKey = 'access_token';
  static const String _askedStudyPlanNotificationKey =
      'asked_study_plan_notification_permission';
  static const String _askedStudyPlanExactAlarmKey =
      'asked_study_plan_exact_alarm_permission';

  // Initialize Hive
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_preferencesBox)) {
      await Hive.openBox<dynamic>(_preferencesBox);
    }
  }

  // Get Hive box
  static Box<dynamic> _getBox() {
    return Hive.box(_preferencesBox);
  }

  // Set theme to light/dark
  static Future<void> setThemeIsLight(bool lightTheme) async {
    await _getBox().put(_lightThemeKey, lightTheme);
  }

  // Get current theme (light or dark)
  static bool getThemeIsLight() {
    return _getBox().get(_lightThemeKey, defaultValue: true) as bool;
  }

  // Save current language
  static Future<void> setCurrentLanguage(String languageCode) async {
    await _getBox().put(_currentLocalKey, languageCode);
  }

  // Get current language
  static Locale getCurrentLocal() {
    String? langCode = _getBox().get(_currentLocalKey) as String?;
    return langCode == null ? const Locale('en') : Locale(langCode);
  }

  // Check if it's the first launch
  static bool isFirstLaunch() {
    return _getBox().get(_isFirstLaunchKey, defaultValue: true) as bool;
  }

  // Mark the app as launched
  static Future<void> markAppLaunched() async {
    await _getBox().put(_isFirstLaunchKey, false);
  }

  // Store access token
  static Future<void> storeAccessToken(String accessToken) async {
    await _getBox().put(_accessTokenKey, accessToken);
  }

  // Get access token
  static String? getAccessToken() {
    return _getBox().get(_accessTokenKey) as String?;
  }

  // Clear all stored data
  static Future<void> clear() async {
    await _getBox().clear();
  }

  /// Whether we already showed the in-app rationale for study plan notifications.
  static bool hasAskedStudyPlanNotificationPermission() {
    return _getBox().get(_askedStudyPlanNotificationKey, defaultValue: false)
        as bool;
  }

  static Future<void> setAskedStudyPlanNotificationPermission(bool value) async {
    await _getBox().put(_askedStudyPlanNotificationKey, value);
  }

  /// Whether we already showed the in-app rationale for exact alarm (Android).
  static bool hasAskedStudyPlanExactAlarmPermission() {
    return _getBox().get(_askedStudyPlanExactAlarmKey, defaultValue: false)
        as bool;
  }

  static Future<void> setAskedStudyPlanExactAlarmPermission(bool value) async {
    await _getBox().put(_askedStudyPlanExactAlarmKey, value);
  }
}
