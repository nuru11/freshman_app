import 'dart:async';
import 'dart:io';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/views/views.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/utils/storages/storages.dart';

enum ReferralValidationStatus { idle, loading, valid, invalid }

class PaymentController extends GetxController {
  final PaymentService _paymentService = PaymentService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController referralTextController = TextEditingController();

  List<PaymentMethod> paymentMethods = <PaymentMethod>[];
  List<Payment> userPayments = <Payment>[];
  List<Package> packages = <Package>[];
  PaymentMethod? selectedPaymentMethod;
  File? selectedReceiptImage;
  String? referralCode;

  int? checkoutPackageId;
  double? amountToPay;
  final Map<int, double> referralAmountByPackageId = {};
  ReferralValidationStatus referralValidationStatus =
      ReferralValidationStatus.idle;
  Timer? _referralDebounceTimer;

  bool isLoading = false;
  bool isLoadingPayments = false;
  bool isCreatingPayment = false;
  User? _user;

  @override
  void onInit() async {
    super.onInit();
    _user = await HiveUserStorage().getUser();
    loadUserPayments();
    loadPackages();

    logger.i('User: $_user');
    HiveUserStorage().listen((event) {
      _user = event;
      loadPaymentMethods();
      loadUserPayments();
      loadPackages();
    }, 'user');
  }

  @override
  void onClose() {
    _referralDebounceTimer?.cancel();
    referralTextController.dispose();
    super.onClose();
  }

  void changeSelectedPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod = method;
    update();
  }

  Package? _packageById(int packageId) {
    for (final pkg in packages) {
      if (pkg.id == packageId) return pkg;
    }
    return null;
  }

  void _clearReferralPricing() {
    referralAmountByPackageId.clear();
    referralValidationStatus = ReferralValidationStatus.idle;
  }

  void beginCheckout(Package package) {
    checkoutPackageId = package.id;
    _referralDebounceTimer?.cancel();

    if (referralValidationStatus == ReferralValidationStatus.valid &&
        referralAmountByPackageId.containsKey(package.id)) {
      amountToPay = referralAmountByPackageId[package.id];
      update();
      return;
    }

    amountToPay = package.price;
    final code = referralCode;
    if (code != null && code.length == 5) {
      referralValidationStatus = ReferralValidationStatus.loading;
      _validateReferralCode(package);
    } else {
      update();
    }
  }

  bool hasReferralDiscountForPackage(int packageId) {
    return referralValidationStatus == ReferralValidationStatus.valid &&
        referralAmountByPackageId.containsKey(packageId);
  }

  double displayAmountForPackage(Package package) {
    return referralAmountByPackageId[package.id] ?? package.price;
  }

  Future<void> loadPaymentMethods() async {
    try {
      isLoading = true;
      update();
      final paymentMethods_ = await _paymentService.getPaymentMethods();
      paymentMethods = paymentMethods_;
    } catch (e) {
      logger.e(e);
      Get.snackbar(
        'Error',
        e is ApiException ? e.message : 'Failed to load payment methods',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> loadUserPayments() async {
    try {
      isLoadingPayments = true;
      update();
      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final userPayments_ = await _paymentService.getUserPayments(device.id);
      userPayments = userPayments_;
    } catch (e) {
      Get.snackbar(
        'Error',
        e is ApiException ? e.message : 'Failed to load payment history',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingPayments = false;
      update();
    }
  }

  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod = method;
    update();
  }

  Future<void> pickReceiptImage({bool afterSheetDismissed = false}) async {
    final image = await ImagePickerPermissions.pickImage(
      picker: _picker,
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
      afterSheetDismissed: afterSheetDismissed,
    );

    if (image != null) {
      selectedReceiptImage = File(image.path);
      update();
    }
  }

  Future<void> takeReceiptPhoto({bool afterSheetDismissed = false}) async {
    final image = await ImagePickerPermissions.pickImage(
      picker: _picker,
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
      afterSheetDismissed: afterSheetDismissed,
    );

    if (image != null) {
      selectedReceiptImage = File(image.path);
      update();
    }
  }

  Future<void> loadPackages() async {
    try {
      isLoading = true;
      update();
      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final grade = _user?.grade;
      final packages_ = await _paymentService.getPackages(
        device.id,
        grade: grade?.id,
      );
      packages = packages_;
      update();

      final code = referralCode;
      if (code != null && code.length == 5 && packages.isNotEmpty) {
        referralValidationStatus = ReferralValidationStatus.loading;
        update();
        await _validateReferralForAllPackages();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e is ApiException ? e.message : 'Failed to load packages',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
      loadPaymentMethods();
    }
  }

  Future<bool> createPayment(int packageId, {String? referralCode}) async {
    isCreatingPayment = true;
    update();

    if (selectedPaymentMethod == null) {
      Get.snackbar(
        'Error',
        'Please select a payment method',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isCreatingPayment = false;
      update();
      return false;
    }

    if (selectedReceiptImage == null) {
      Get.snackbar(
        'Error',
        'Please upload a receipt image',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isCreatingPayment = false;
      update();
      return false;
    }

    final package = _packageById(packageId);
    if (package == null) {
      Get.snackbar(
        'Error',
        'Package not found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isCreatingPayment = false;
      update();
      return false;
    }

    final paymentAmount = checkoutPackageId == packageId && amountToPay != null
        ? amountToPay!
        : (referralAmountByPackageId[packageId] ?? package.price);

    try {
      isCreatingPayment = true;
      update();
      final device = await UserDevice.getDeviceInfo(_user?.phoneNumber ?? '');
      final receiptFile = selectedReceiptImage!;
      await _paymentService.uploadReceipt(
        file: receiptFile,
        package: packageId,
        paymentMethod: selectedPaymentMethod!.id,
        amount: paymentAmount,
        device: device.id,
        referralCode: referralCode,
      );

      Get.snackbar(
        'Success',
        'Payment submitted successfully! It will be reviewed by admin!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      selectedPaymentMethod = null;
      selectedReceiptImage = null;
      referralCode = null;
      checkoutPackageId = null;
      amountToPay = null;
      _clearReferralPricing();
      referralTextController.clear();

      loadUserPayments();

      Get.offAllNamed(VIEWS.home.path);
      return true;
    } catch (e) {
      logger.e(e);
      Get.snackbar(
        'Error',
        e is ApiException ? e.message : 'Failed to create payment',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isCreatingPayment = false;
      update();
    }
  }

  void clearSelection() {
    selectedPaymentMethod = null;
    selectedReceiptImage = null;
    referralCode = null;
    checkoutPackageId = null;
    amountToPay = null;
    _clearReferralPricing();
    _referralDebounceTimer?.cancel();
    referralTextController.clear();
    update();
  }

  void setReferralCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    referralCode = normalized == null || normalized.isEmpty ? null : normalized;
    _referralDebounceTimer?.cancel();

    if (referralCode == null || referralCode!.isEmpty) {
      _clearReferralPricing();
      update();
      return;
    }

    if (referralCode!.length < 5) {
      _clearReferralPricing();
      update();
      return;
    }

    if (packages.isEmpty) {
      update();
      return;
    }

    referralValidationStatus = ReferralValidationStatus.loading;
    update();

    _referralDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      final checkoutId = checkoutPackageId;
      final checkoutPackage =
          checkoutId != null ? _packageById(checkoutId) : null;
      if (checkoutPackage != null) {
        _validateReferralCode(checkoutPackage);
      } else {
        _validateReferralForAllPackages();
      }
    });
  }

  Future<void> _validateReferralForAllPackages() async {
    final code = referralCode;
    if (code == null || code.length != 5 || packages.isEmpty) {
      return;
    }

    try {
      final results = await Future.wait(
        packages.map(
          (package) => _paymentService.validateReferralCode(
            code: code,
            packageId: package.id,
          ),
        ),
      );

      referralAmountByPackageId.clear();
      for (var i = 0; i < packages.length; i++) {
        referralAmountByPackageId[packages[i].id] = results[i].amountToPay;
      }

      final isValid = results.isNotEmpty && results.first.valid;
      referralValidationStatus = isValid
          ? ReferralValidationStatus.valid
          : ReferralValidationStatus.invalid;

      if (!isValid) {
        referralAmountByPackageId.clear();
      }
    } catch (e) {
      logger.e(e);
      referralValidationStatus = ReferralValidationStatus.invalid;
      referralAmountByPackageId.clear();
      Get.snackbar(
        'Referral code',
        e is ApiException ? e.message : 'Could not validate referral code',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      update();
    }
  }

  Future<void> _validateReferralCode(Package package) async {
    final code = referralCode;
    if (code == null || code.length != 5) {
      return;
    }

    try {
      final result = await _paymentService.validateReferralCode(
        code: code,
        packageId: package.id,
      );
      amountToPay = result.amountToPay;
      referralAmountByPackageId[package.id] = result.amountToPay;
      referralValidationStatus = result.valid
          ? ReferralValidationStatus.valid
          : ReferralValidationStatus.invalid;

      if (!result.valid) {
        referralAmountByPackageId.remove(package.id);
      }
    } catch (e) {
      logger.e(e);
      referralValidationStatus = ReferralValidationStatus.invalid;
      amountToPay = package.price;
      referralAmountByPackageId.remove(package.id);
      Get.snackbar(
        'Referral code',
        e is ApiException ? e.message : 'Could not validate referral code',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      update();
    }
  }

  Color getPaymentStatusColor(bool isCompleted) {
    if (isCompleted) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  IconData getPaymentStatusIcon(bool isCompleted) {
    if (isCompleted) {
      return Icons.check_circle;
    } else {
      return Icons.pending;
    }
  }
}
