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
}
