import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/utils/screen_capture_guard.dart';

class RecordingBlockedOverlay extends StatelessWidget {
  final VoidCallback onBack;

  const RecordingBlockedOverlay({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Screen recording is not allowed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MovingWatermark extends StatefulWidget {
  final String label;

  const MovingWatermark({super.key, required this.label});

  @override
  State<MovingWatermark> createState() => _MovingWatermarkState();
}

class _MovingWatermarkState extends State<MovingWatermark> {
  static const List<Alignment> _alignments = [
    Alignment(-0.82, -0.68),
    Alignment(0.82, -0.42),
    Alignment(0.7, 0.68),
    Alignment(-0.78, 0.36),
    Alignment(0.0, -0.08),
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _alignments.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedAlign(
        alignment: _alignments[_index],
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Text(
            widget.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Turns capture protection on for the lifetime of this widget and covers
/// [child] with the watermark or the recording blackout.
class ContentProtectionScope extends StatefulWidget {
  final Widget child;
  final VoidCallback onBack;

  const ContentProtectionScope({
    super.key,
    required this.child,
    required this.onBack,
  });

  @override
  State<ContentProtectionScope> createState() => _ContentProtectionScopeState();
}

class _ContentProtectionScopeState extends State<ContentProtectionScope> {
  final ScreenCaptureGuard _guard = ScreenCaptureGuard();

  @override
  void initState() {
    super.initState();
    _guard.enable();
  }

  @override
  void dispose() {
    _guard.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_guard.isScreenCaptured.value) {
        return RecordingBlockedOverlay(onBack: widget.onBack);
      }

      final label = _guard.watermarkLabel;
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (label.isNotEmpty) MovingWatermark(label: label),
        ],
      );
    });
  }
}
