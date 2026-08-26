import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vector_academy/components/ui/themes/light_theme.dart';
import 'package:vector_academy/utils/app_clock.dart';
import 'package:vector_academy/utils/ethiopian_time.dart';

String formatNotifyCountdown(Duration remaining) {
  if (remaining.isNegative || remaining == Duration.zero) {
    return 'Notify time passed';
  }
  final days = remaining.inDays;
  final hours = remaining.inHours.remainder(24);
  final minutes = remaining.inMinutes.remainder(60);
  final seconds = remaining.inSeconds.remainder(60);
  if (days > 0) {
    return 'in ${days}d ${hours}h';
  }
  if (hours > 0) {
    return 'in ${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    return 'in ${minutes}m ${seconds}s';
  }
  return 'in ${seconds}s';
}

String formatNotifyLabel(DateTime fireAt) {
  final remaining = fireAt.difference(AppClock.now());
  if (remaining.isNegative || remaining == Duration.zero) {
    return 'Notify time passed';
  }
  final clock = EthiopianTime.formatWesternDateTimeClock(fireAt);
  return 'Notifies at $clock · ${formatNotifyCountdown(remaining)}';
}

class NotifyCountdownLabel extends StatefulWidget {
  const NotifyCountdownLabel({
    super.key,
    required this.fireAt,
    this.alarmsOn = true,
    this.style,
  });

  final DateTime? fireAt;
  final bool alarmsOn;
  final TextStyle? style;

  @override
  State<NotifyCountdownLabel> createState() => _NotifyCountdownLabelState();
}

class _NotifyCountdownLabelState extends State<NotifyCountdownLabel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.alarmsOn) return const SizedBox.shrink();
    final fireAt = widget.fireAt;
    final text = fireAt == null
        ? 'Notify time passed'
        : formatNotifyLabel(fireAt);
    return Text(
      text,
      style: widget.style ??
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
    );
  }
}
