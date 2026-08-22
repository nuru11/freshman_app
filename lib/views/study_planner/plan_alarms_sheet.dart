import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';
import 'package:vector_academy/models/study_plan.dart';

Future<void> showPlanAlarmsSheet({
  required StudyPlan plan,
  required Future<void> Function(bool enabled, List<StudyPlanAlarm> alarms)
      onSave,
}) async {
  await Get.bottomSheet(
    _PlanAlarmsSheet(plan: plan, onSave: onSave),
    isScrollControlled: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );
}

class _PlanAlarmsSheet extends StatefulWidget {
  const _PlanAlarmsSheet({required this.plan, required this.onSave});

  final StudyPlan plan;
  final Future<void> Function(bool enabled, List<StudyPlanAlarm> alarms) onSave;

  @override
  State<_PlanAlarmsSheet> createState() => _PlanAlarmsSheetState();
}

class _PlanAlarmsSheetState extends State<_PlanAlarmsSheet> {
  late bool _enabled;
  late List<StudyPlanAlarm> _alarms;

  static const _offsets = [0, 5, 10, 15, 30, 60];
  static const _sounds = ['default', 'alarm', 'chime'];
  static const _vibrations = ['default', 'short', 'long'];
  static const _snoozes = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    _enabled = widget.plan.alarmsEnabled;
    _alarms = widget.plan.alarms.isEmpty
        ? [StudyPlanAlarm.defaultAlarm()]
        : List<StudyPlanAlarm>.from(widget.plan.alarms);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alarms',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable alarms'),
            value: _enabled,
            activeThumbColor: primaryColor,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 8),
          ...List.generate(_alarms.length, (index) {
            final alarm = _alarms[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Alarm ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_alarms.length > 1)
                          IconButton(
                            onPressed: () =>
                                setState(() => _alarms.removeAt(index)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    _dropdown<int>(
                      label: 'When',
                      value: _offsets.contains(alarm.offsetMinutes)
                          ? alarm.offsetMinutes
                          : 15,
                      items: {
                        for (final m in _offsets)
                          m: m == 0 ? 'At start time' : '$m min before',
                      },
                      onChanged: (v) => setState(() {
                        _alarms[index] = alarm.copyWith(offsetMinutes: v);
                      }),
                    ),
                    _dropdown<String>(
                      label: 'Sound',
                      value: alarm.sound,
                      items: {
                        for (final s in _sounds)
                          s: s[0].toUpperCase() + s.substring(1),
                      },
                      onChanged: (v) => setState(() {
                        _alarms[index] = alarm.copyWith(sound: v);
                      }),
                    ),
                    _dropdown<String>(
                      label: 'Vibration',
                      value: alarm.vibration,
                      items: {
                        for (final s in _vibrations)
                          s: s[0].toUpperCase() + s.substring(1),
                      },
                      onChanged: (v) => setState(() {
                        _alarms[index] = alarm.copyWith(vibration: v);
                      }),
                    ),
                    _dropdown<int>(
                      label: 'Snooze',
                      value: _snoozes.contains(alarm.snoozeMinutes)
                          ? alarm.snoozeMinutes
                          : 5,
                      items: {for (final m in _snoozes) m: '$m minutes'},
                      onChanged: (v) => setState(() {
                        _alarms[index] = alarm.copyWith(snoozeMinutes: v);
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() {
              _alarms.add(StudyPlanAlarm.defaultAlarm());
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add another alarm'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await widget.onSave(_enabled, _alarms);
              Get.back();
            },
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save alarms'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<T>(
        // ignore: deprecated_member_use
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
