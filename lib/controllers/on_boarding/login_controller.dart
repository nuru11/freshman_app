import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/services/api/device.dart';
import 'package:vector_academy/utils/utils.dart';

class LoginController extends GetxController {
  final authService = Get.find<AuthService>();
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void login() async {
    if (formKey.currentState!.validate()) {
      _setLoading(true);

      try {
        final phone = phoneController.text;
        final password = passwordController.text;

        final response = await UserService().loginUser(phone, password);

        BaseApiClient.setTokens(
          response.tokens.access,
          response.tokens.refresh,
        );

        final user = await UserService().getUser();

        await authService.saveAuthToken(response.tokens);
        await authService.saveUser(user);

        try {
          await DeviceService().registerDevice(user.phoneNumber);
        } catch (e) {
          logger.w('Device registration failed after login: $e');
        }

        Get.offAllNamed(VIEWS.home.path);
        AppSnackbar.showSuccessAfterNav('Success', 'Login successful!');
      } on ApiException catch (e) {
        AppSnackbar.showError('Login Failed', e.message);
      } on DioException catch (e) {
        AppSnackbar.showError(
          'Login Failed',
          ApiErrorMessage.from(e, fallback: 'Failed to login'),
        );
      } catch (e) {
        AppSnackbar.showError(
          'Login Failed',
          ApiErrorMessage.from(e, fallback: 'Failed to login'),
        );
      } finally {
        _setLoading(false);
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    update();
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
