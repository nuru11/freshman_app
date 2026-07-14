import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/services/api/device.dart';

class RegisterController extends GetxController {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();

  Grade? _selectedGrade;
  Grade? get selectedGrade => _selectedGrade;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  bool _isConfirmPasswordVisible = false;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;

  bool _allowStreamSelection = false;
  bool get allowStreamSelection => _allowStreamSelection;

  bool _hasAcceptedPrivacyPolicy = false;
  bool get hasAcceptedPrivacyPolicy => _hasAcceptedPrivacyPolicy;

  // Grade and Stream properties

  String? _selectedStream;
  String? get selectedStream => _selectedStream;

  // Grade options
  List<Grade> gradeOptions = [];

  void setSelectedGrade(Grade? grade) {
    _selectedGrade = grade;
    changeAllowStreamSelection();
    update();
  }

  void setSelectedStream(String? stream) {
    _selectedStream = stream;
    update();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    update();
  }

  void changeAllowStreamSelection() {
    if (_selectedGrade?.name == 'Grade 9' ||
        _selectedGrade?.name == 'Grade 10') {
      _allowStreamSelection = false;
    } else {
      _allowStreamSelection = true;
    }
    update();
  }

  void loadGrades() async {
    try {
      gradeOptions = await GradeService().getGrades(backendAppPackage);
      gradeOptions.sort((a, b) => a.name.compareTo(b.name));
      update();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load grades');
    }
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    update();
  }

  void togglePrivacyPolicyAcceptance(bool? value) {
    _hasAcceptedPrivacyPolicy = value ?? false;
    update();
  }

  void register() async {
    if (!_hasAcceptedPrivacyPolicy) {
      Get.snackbar(
        'Privacy Policy Required',
        'Please accept the Privacy Policy and Terms & Conditions to continue',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (formKey.currentState!.validate()) {
      _setLoading(true);

      try {
        final response = await UserService().registerUser(
          nameController.text,
          phoneController.text,
          passwordController.text,
          selectedGrade?.id ?? 0,
        );

        logger.i(response);

        await AuthService().saveAuthToken(response.tokens);
        final user = await UserService().getUser();
        await AuthService().saveUser(user);

        BaseApiClient.setTokens(
          response.tokens.access,
          response.tokens.refresh,
        );

        await DeviceService().registerDevice(user.phoneNumber);

        Get.offAllNamed(VIEWS.home.path);

        Get.snackbar(
          'Success',
          'Registration successful! Please verify your phone number.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to verify phone page
      } on DioException catch (e) {
        Get.snackbar(
          'Registration Failed',
          e.toString(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } on ApiException catch (e) {
        Get.snackbar(
          'Registration Failed',
          e.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } catch (e) {
        logger.e(e.toString());
        Get.snackbar(
          'Error',
          'Registration failed. Please try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
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
  void onInit() {
    super.onInit();
    // Recreate formKey to avoid GlobalKey conflicts when widget rebuilds
    formKey = GlobalKey<FormState>();
    loadGrades();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
