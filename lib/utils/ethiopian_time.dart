import 'package:flutter/material.dart';

/// Ethiopian (local) clock is 6 hours behind Western (foreign) clock.
/// Minutes are unchanged.
class EthiopianTime {
  static const int offsetHours = 6;

  /// Convert Ethiopian local hour → Western hour.
  static int toWesternHour(int ethiopianHour) =>
      (ethiopianHour + offsetHours) % 24;

  /// Convert Western hour → Ethiopian local hour.
  static int toEthiopianHour(int westernHour) =>
      (westernHour - offsetHours + 24) % 24;

  /// Convert a [TimeOfDay] from Ethiopian → Western for storage.
  static TimeOfDay toWestern(TimeOfDay ethiopian) => TimeOfDay(
        hour: toWesternHour(ethiopian.hour),
        minute: ethiopian.minute,
      );

  /// Convert a [TimeOfDay] from Western → Ethiopian for display.
  static TimeOfDay toEthiopian(TimeOfDay western) => TimeOfDay(
        hour: toEthiopianHour(western.hour),
        minute: western.minute,
      );

  /// Format as 12-hour with Day/Night, e.g. `9:00 Day`, `8:30 Night`.
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'Day' : 'Night';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  /// Convert a Western-stored [DateTime] clock to Ethiopian, then format.
  static String formatWesternDateTimeClock(DateTime dateTime) {
    return formatTimeOfDay(toEthiopian(TimeOfDay.fromDateTime(dateTime)));
  }

  /// 12-hour time picker with Day/Night period labels (not AM/PM).
  static Future<TimeOfDay?> showDayNightTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          delegates: const [_DayNightMaterialLocalizationsDelegate()],
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
  }
}

class _DayNightMaterialLocalizations extends DefaultMaterialLocalizations {
  const _DayNightMaterialLocalizations();

  @override
  String get anteMeridiemAbbreviation => 'Day';

  @override
  String get postMeridiemAbbreviation => 'Night';
}

class _DayNightMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _DayNightMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      const _DayNightMaterialLocalizations();

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) =>
      false;
}
