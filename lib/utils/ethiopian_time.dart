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
    return formatTimeOfDay(
      toEthiopian(TimeOfDay.fromDateTime(dateTime.toLocal())),
    );
  }

  static TimeOfDay fromHour12({
    required int hour12,
    required int minute,
    required bool isDay,
  }) {
    final clampedHour = hour12.clamp(1, 12);
    final hour24 = isDay
        ? (clampedHour == 12 ? 0 : clampedHour)
        : (clampedHour == 12 ? 12 : clampedHour + 12);
    return TimeOfDay(hour: hour24, minute: minute.clamp(0, 59));
  }

  /// Day/Night picker that ignores the device 12/24-hour setting.
  static Future<TimeOfDay?> showDayNightTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _DayNightTimePickerDialog(initialTime: initialTime),
    );
  }
}

class _DayNightTimePickerDialog extends StatefulWidget {
  const _DayNightTimePickerDialog({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_DayNightTimePickerDialog> createState() =>
      _DayNightTimePickerDialogState();
}

class _DayNightTimePickerDialogState extends State<_DayNightTimePickerDialog> {
  static const _itemExtent = 40.0;

  late int _hour12;
  late int _minute;
  late bool _isDay;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final time = widget.initialTime;
    _hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    _minute = time.minute;
    _isDay = time.period == DayPeriod.am;
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay get _selected => EthiopianTime.fromHour12(
        hour12: _hour12,
        minute: _minute,
        isDay: _isDay,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Select time'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _itemExtent * 5,
              child: Row(
                children: [
                  Expanded(
                    child: _Wheel(
                      controller: _hourController,
                      itemCount: 12,
                      labelFor: (index) => '${index + 1}',
                      onSelected: (index) =>
                          setState(() => _hour12 = index + 1),
                    ),
                  ),
                  Text(
                    ':',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: _Wheel(
                      controller: _minuteController,
                      itemCount: 60,
                      labelFor: (index) => index.toString().padLeft(2, '0'),
                      onSelected: (index) => setState(() => _minute = index),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Day')),
                ButtonSegment(value: false, label: Text('Night')),
              ],
              selected: {_isDay},
              onSelectionChanged: (value) {
                setState(() => _isDay = value.first);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.itemCount,
    required this.labelFor,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) labelFor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _DayNightTimePickerDialogState._itemExtent,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          return Center(
            child: Text(
              labelFor(index),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        },
      ),
    );
  }
}
