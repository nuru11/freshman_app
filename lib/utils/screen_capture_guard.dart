import 'package:get/get.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:vector_academy/services/auth.dart';
import 'package:vector_academy/utils/utils.dart';

/// Blocks screenshots and system screen recording while a protected screen
/// is open. [onCaptureStarted] and [onCaptureEnded] run on the rising and
/// falling edges of iOS screen capture.
class ScreenCaptureGuard {
  final RxBool isScreenCaptured = false.obs;

  void Function()? onCaptureStarted;
  void Function()? onCaptureEnded;

  bool _closed = false;

  String get watermarkLabel {
    if (!Get.isRegistered<AuthService>()) return '';
    final user = Get.find<AuthService>().user.value;
    if (user == null) return '';
    final phone = user.phoneNumber.trim();
    if (phone.isNotEmpty) return phone;
    return 'ID ${user.id}';
  }

  Future<void> enable() async {
    _closed = false;
    try {
      await ScreenProtector.protectDataLeakageOn();
      if (_closed) {
        await disable();
        return;
      }
      await ScreenProtector.preventScreenshotOn();
      if (_closed) {
        await disable();
        return;
      }
      ScreenProtector.addListener(null, _onScreenRecord);
      if (_closed) {
        await disable();
        return;
      }
      final recording = await ScreenProtector.isRecording();
      if (_closed) {
        await disable();
        return;
      }
      if (recording) {
        _onScreenRecord(true);
      }
    } catch (e) {
      logger.w('Could not enable screen protection: $e');
    }
  }

  Future<void> disable() async {
    _closed = true;
    isScreenCaptured.value = false;
    try {
      ScreenProtector.removeListener();
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (e) {
      logger.w('Could not disable screen protection: $e');
    }
  }

  void _onScreenRecord(bool isCaptured) {
    if (_closed) return;
    if (isCaptured) {
      final started = !isScreenCaptured.value;
      isScreenCaptured.value = true;
      if (started) onCaptureStarted?.call();
      return;
    }

    final ended = isScreenCaptured.value;
    isScreenCaptured.value = false;
    if (ended) onCaptureEnded?.call();
  }
}
