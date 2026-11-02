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

/// Turns capture protection on for the lifetime of this widget and covers
/// [child] with the recording blackout while the screen is being recorded.
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

      return widget.child;
    });
  }
}
