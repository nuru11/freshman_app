import 'dart:io';

/// Real-world clock using HTTP Date skew so planner alarms still fire
/// at the intended moment when the device clock is wrong.
class AppClock {
  AppClock._();

  static Duration _skew = Duration.zero;

  static const Duration notifyGracePast = Duration(minutes: 2);
  static const Duration notifyImminentDelay = Duration(seconds: 15);

  static Duration get skew => _skew;

  /// Real local time: device clock plus last known server skew.
  static DateTime now() => DateTime.now().add(_skew);

  static void syncFromHttpDate(String? dateHeader) {
    if (dateHeader == null || dateHeader.trim().isEmpty) return;
    try {
      final serverNow = HttpDate.parse(dateHeader.trim()).toLocal();
      _skew = serverNow.difference(DateTime.now());
    } catch (_) {}
  }

  /// Device-clock instant that corresponds to [realFire] on the real clock.
  static DateTime toDeviceTime(DateTime realFire) {
    return DateTime.now().add(realFire.difference(now()));
  }

  /// If [scheduled] is slightly in the past, fire soon instead of tomorrow.
  static DateTime? applyNotifyGrace(DateTime scheduled, [DateTime? from]) {
    final origin = from ?? now();
    if (scheduled.isAfter(origin)) return scheduled;
    if (origin.difference(scheduled) <= notifyGracePast) {
      return origin.add(notifyImminentDelay);
    }
    return null;
  }
}
