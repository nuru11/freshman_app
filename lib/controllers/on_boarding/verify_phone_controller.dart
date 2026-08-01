import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';

class VerifyPhoneController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _canResend = false;
  bool get canResend => _canResend;

  int _resendTimer = 60;
  int get resendTimer => _resendTimer;

  Timer? _timer;

  String phoneNumber = '';

  @override
  void onInit() {
    super.onInit();
    phoneNumber = Get.arguments?['phone'] ?? '';
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    update();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        _resendTimer--;
        update();
      } else {
        _canResend = true;
        timer.cancel();
        update();
      }
    });
  }

  void verifyOTP() async {
    logger.i('Verifying OTP...');
    if (formKey.currentState!.validate()) {
      _setLoading(true);

      try {
        final response = await UserService().verifyPhone(
          phoneNumber,
          otpController.text,
        );
        logger.i(response);

        if (otpController.text.length == 6) {
          Get.offAllNamed(VIEWS.home.path);
          AppSnackbar.showSuccessAfterNav(
            'Success',
            'Phone verified successfully!',
          );
        } else {
          logger.e('Invalid OTP. Please try again.');
          AppSnackbar.showError('Error', 'Invalid OTP. Please try again.');
        }
      } catch (e) {
        logger.e(e.toString());
        AppSnackbar.showError(
          'Error',
          ApiErrorMessage.from(e, fallback: 'Failed to verify OTP. Please try again.'),
        );
      } finally {
        _setLoading(false);
      }
    }
  }

  void resendOTP() async {
    if (!_canResend) return;

    try {
      // Local cooldown only — no resend API is wired yet.
      await Future.delayed(Duration(seconds: 1));

      AppSnackbar.showInfo(
        'OTP Ready',
        'You can enter a new OTP for $phoneNumber',
      );

      _startResendTimer();
    } catch (e) {
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Failed to resend OTP. Please try again.'),
      );
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    update();
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}
