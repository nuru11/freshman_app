import 'dart:async';
import 'dart:io';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/views/views.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/api/device.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/utils/storages/storages.dart';

enum ReferralValidationStatus { idle, loading, valid, invalid }

enum RecipientLookupStatus { idle, loading, found, error }

class PaymentController extends GetxController {
  final PaymentService _paymentService = PaymentService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController referralTextController = TextEditingController();
  final TextEditingController recipientPhoneController = TextEditingController();
  static final RegExp _recipientPhonePattern = RegExp(r'^(7|9)\d{8}$');

  List<PaymentMethod> paymentMethods = <PaymentMethod>[];
  List<Payment> userPayments = <Payment>[];
  List<Package> packages = <Package>[];
  PaymentMethod? selectedPaymentMethod;
  File? selectedReceiptImage;
  String? referralCode;
  bool purchaseForSelf = true;
  String recipientPhone = '';
  RecipientLookupStatus recipientLookupStatus = RecipientLookupStatus.idle;
  String? recipientLookupMessage;
  List<GiftRecipientDevice> recipientDevices = [];
  int? selectedRecipientDeviceId;
  int? recipientGradeId;
  String? recipientGradeName;
  bool isLoadingGiftPackages = false;
  bool _showingRecipientPackages = false;
  int _packageLoadGeneration = 0;
  Timer? _recipientDebounceTimer;

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
    _recipientDebounceTimer?.cancel();
    referralTextController.dispose();
    recipientPhoneController.dispose();
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

  String normalizeGiftPhone(String raw) {
    var phone = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('+251')) {
      phone = phone.substring(4);
    } else if (phone.startsWith('251') && phone.length == 12) {
      phone = phone.substring(3);
    } else if (phone.startsWith('0') && phone.length == 10) {
      phone = phone.substring(1);
    }
    return phone;
  }

  void _resetGiftSelection() {
    _recipientDebounceTimer?.cancel();
    purchaseForSelf = true;
    recipientPhone = '';
    recipientLookupStatus = RecipientLookupStatus.idle;
    recipientLookupMessage = null;
    recipientDevices = [];
    selectedRecipientDeviceId = null;
    recipientGradeId = null;
    recipientGradeName = null;
    _showingRecipientPackages = false;
    isLoadingGiftPackages = false;
    recipientPhoneController.clear();
  }

  void _clearRecipientDevices() {
    recipientDevices = [];
    selectedRecipientDeviceId = null;
  }

  bool get showingRecipientGradePackages =>
      !purchaseForSelf && recipientGradeId != null;

  void _clearRecipientGrade() {
    recipientGradeId = null;
    recipientGradeName = null;
  }

  Future<void> _restoreBuyerPackagesIfNeeded() async {
    _clearRecipientGrade();
    if (!_showingRecipientPackages) {
      isLoadingGiftPackages = false;
      return;
    }
    _showingRecipientPackages = false;
    await loadPackages(buyerGrade: true, fullScreen: false);
  }

  void _withholdRecipientPackages() {
    _clearRecipientGrade();
    _showingRecipientPackages = true;
    packages = [];
    _clearReferralPricing();
    isLoadingGiftPackages = false;
  }

  GiftRecipientDevice? get selectedRecipientDevice {
    for (final device in recipientDevices) {
      if (device.id == selectedRecipientDeviceId) return device;
    }
    return null;
  }

  String get selectedRecipientDeviceLabel =>
      selectedRecipientDevice?.label ?? '';

  String get checkoutRecipientLabel {
    if (purchaseForSelf) return 'Course for: Myself';
    if (selectedRecipientDeviceLabel.isEmpty) {
      return 'Gift for: $recipientPhone';
    }
    return 'Gift for: $recipientPhone · $selectedRecipientDeviceLabel';
  }

  void selectRecipientDevice(int deviceId) {
    selectedRecipientDeviceId = deviceId;
    update();
  }

  void _showGiftError(String message) {
    AppSnackbar.showError('Gift', message);
  }

  bool _ensureGiftRecipient() {
    if (purchaseForSelf) return true;
    if (recipientLookupStatus != RecipientLookupStatus.found ||
        !_recipientPhonePattern.hasMatch(recipientPhone)) {
      _showGiftError(
        recipientLookupMessage ??
            'Enter the phone number of an active account.',
      );
      return false;
    }
    if (recipientDevices.isEmpty) {
      _showGiftError(
        'This account has no registered device. The recipient must open the app on a device first.',
      );
      return false;
    }
    if (selectedRecipientDevice == null) {
      _showGiftError('Choose one device to unlock.');
      return false;
    }
    return true;
  }

  void setPurchaseForSelf(bool forSelf) {
    purchaseForSelf = forSelf;
    if (forSelf) {
      _recipientDebounceTimer?.cancel();
      recipientLookupStatus = RecipientLookupStatus.idle;
      recipientLookupMessage = null;
      _clearRecipientDevices();
      _restoreBuyerPackagesIfNeeded();
      update();
      return;
    }
    setRecipientPhone(recipientPhoneController.text);
  }

  void setRecipientPhone(String value) {
    recipientPhone = normalizeGiftPhone(value);
    _recipientDebounceTimer?.cancel();
    if (purchaseForSelf) {
      update();
      return;
    }
    if (!_recipientPhonePattern.hasMatch(recipientPhone)) {
      recipientLookupStatus = recipientPhone.isEmpty
          ? RecipientLookupStatus.idle
          : RecipientLookupStatus.error;
      recipientLookupMessage = recipientPhone.isEmpty
          ? null
          : 'Enter a valid phone number.';
      _clearRecipientDevices();
      _restoreBuyerPackagesIfNeeded();
      update();
      return;
    }
    recipientLookupStatus = RecipientLookupStatus.loading;
    recipientLookupMessage = null;
    _clearRecipientDevices();
    _clearRecipientGrade();
    _packageLoadGeneration++;
    isLoadingGiftPackages = true;
    update();
    final phone = recipientPhone;
    _recipientDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _lookupRecipient(phone);
    });
  }

  Future<void> _lookupRecipient(String phone) async {
    try {
      final lookup = await _paymentService.lookupGiftRecipient(phone);
      if (purchaseForSelf || recipientPhone != phone) return;
      recipientDevices = lookup.devices;
      if (lookup.devices.isEmpty) {
        selectedRecipientDeviceId = null;
        recipientLookupStatus = RecipientLookupStatus.error;
        recipientLookupMessage =
            'This account has no registered device. The recipient must open the app on a device first.';
        await _restoreBuyerPackagesIfNeeded();
      } else if (lookup.gradeId == null) {
        selectedRecipientDeviceId = lookup.devices.length == 1
            ? lookup.devices.first.id
            : null;
        recipientLookupStatus = RecipientLookupStatus.error;
        recipientLookupMessage =
            'This account has no grade. The student must choose a grade in the app first.';
        _withholdRecipientPackages();
      } else {
        selectedRecipientDeviceId = lookup.devices.length == 1
            ? lookup.devices.first.id
            : null;
        recipientGradeId = lookup.gradeId;
        recipientGradeName = lookup.gradeName;
        _showingRecipientPackages = true;
        recipientLookupStatus = RecipientLookupStatus.found;
        recipientLookupMessage = lookup.gradeName == null
            ? 'Active account found'
            : 'Active account found · ${lookup.gradeName}';
        update();
        await loadPackages(gradeId: lookup.gradeId, fullScreen: false);
        return;
      }
    } catch (e) {
      if (purchaseForSelf || recipientPhone != phone) return;
      recipientLookupStatus = RecipientLookupStatus.error;
      recipientLookupMessage = ApiErrorMessage.from(
        e,
        fallback: 'No active account is registered with that phone number.',
      );
      await _restoreBuyerPackagesIfNeeded();
    }
    update();
  }

  bool beginCheckout(Package package) {
    if (!_ensureGiftRecipient()) {
      return false;
    }
    checkoutPackageId = package.id;
    _referralDebounceTimer?.cancel();

    if (referralValidationStatus == ReferralValidationStatus.valid &&
        referralAmountByPackageId.containsKey(package.id)) {
      amountToPay = referralAmountByPackageId[package.id];
      update();
      return true;
    }

    amountToPay = package.price;
    final code = referralCode;
    if (code != null && code.length == 5) {
      referralValidationStatus = ReferralValidationStatus.loading;
      _validateReferralCode(package);
    } else {
      update();
    }
    return true;
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
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Failed to load payment methods'),
      );
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<DeviceInfo> _ensureDeviceRegistered() async {
    final phone = _user?.phoneNumber ?? '';
    try {
      // registerDevice remints once on ownership conflict.
      await DeviceService().registerDevice(phone);
    } catch (e) {
      logger.w('Device re-registration before payment failed: $e');
    }
    return UserDevice.getDeviceInfo(phone);
  }

  Future<void> _uploadReceiptWithDeviceConflictRetry({
    required File receiptFile,
    required int packageId,
    required double paymentAmount,
    required String? referralCode,
    required DeviceInfo device,
    String? recipientPhone,
    int? recipientDevice,
  }) async {
    try {
      await _paymentService.uploadReceipt(
        file: receiptFile,
        package: packageId,
        paymentMethod: selectedPaymentMethod!.id,
        amount: paymentAmount,
        device: device.id,
        referralCode: referralCode,
        recipientPhone: recipientPhone,
        recipientDevice: recipientDevice,
      );
    } catch (e) {
      if (!DeviceService.isOwnedByAnotherUser(e)) rethrow;

      final phone = _user?.phoneNumber ?? '';
      logger.w(
        'Receipt upload device conflict; reminting and retrying once: $e',
      );
      await UserDevice.remintDeviceId(phone);
      try {
        await DeviceService().registerDevice(phone);
      } catch (regError) {
        logger.w('Device register after remint failed: $regError');
      }
      final retryDevice = await UserDevice.getDeviceInfo(phone);
      await _paymentService.uploadReceipt(
        file: receiptFile,
        package: packageId,
        paymentMethod: selectedPaymentMethod!.id,
        amount: paymentAmount,
        device: retryDevice.id,
        referralCode: referralCode,
        recipientPhone: recipientPhone,
        recipientDevice: recipientDevice,
      );
    }
  }

  Future<void> loadUserPayments() async {
    try {
      isLoadingPayments = true;
      update();
      final device = await _ensureDeviceRegistered();
      final userPayments_ = await _paymentService.getUserPayments(device.id);
      userPayments = userPayments_;
    } catch (e) {
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Failed to load payment history'),
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

  Future<void> loadPackages({
    int? gradeId,
    bool buyerGrade = false,
    bool fullScreen = true,
  }) async {
    final generation = ++_packageLoadGeneration;
    if (!buyerGrade &&
        gradeId == null &&
        !purchaseForSelf &&
        recipientGradeId != null) {
      gradeId = recipientGradeId;
    }
    try {
      if (fullScreen) {
        isLoading = true;
      } else {
        isLoadingGiftPackages = true;
      }
      update();
      final device = await _ensureDeviceRegistered();
      final int? resolvedGradeId = buyerGrade || gradeId == null
          ? _user?.grade.id
          : gradeId;
      final packages_ = await _paymentService.getPackages(
        device.id,
        grade: resolvedGradeId,
      );
      if (generation != _packageLoadGeneration) return;
      if (!buyerGrade && gradeId != null && recipientGradeId != gradeId) {
        return;
      }
      packages = packages_;
      update();

      final code = referralCode;
      if (code != null && code.length == 5 && packages.isNotEmpty) {
        referralValidationStatus = ReferralValidationStatus.loading;
        update();
        await _validateReferralForAllPackages();
      }
    } catch (e) {
      if (generation != _packageLoadGeneration) return;
      if (!fullScreen && !buyerGrade && gradeId != null) {
        packages = [];
      }
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Failed to load packages'),
      );
    } finally {
      if (generation != _packageLoadGeneration) return;
      if (fullScreen) {
        isLoading = false;
        loadPaymentMethods();
      } else {
        isLoadingGiftPackages = false;
        update();
      }
    }
  }

  Future<bool> createPayment(int packageId, {String? referralCode}) async {
    isCreatingPayment = true;
    update();

    if (selectedPaymentMethod == null) {
      AppSnackbar.showError('Error', 'Please select a payment method');
      isCreatingPayment = false;
      update();
      return false;
    }

    if (selectedReceiptImage == null) {
      AppSnackbar.showError('Error', 'Please upload a receipt image');
      isCreatingPayment = false;
      update();
      return false;
    }

    final package = _packageById(packageId);
    if (package == null) {
      AppSnackbar.showError('Error', 'Package not found');
      isCreatingPayment = false;
      update();
      return false;
    }

    if (!_ensureGiftRecipient()) {
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
      final device = await _ensureDeviceRegistered();
      if (device.id.trim().isEmpty) {
        AppSnackbar.showError(
          'Error',
          'Could not identify this device. Please restart the app and try again.',
        );
        return false;
      }
      final receiptFile = selectedReceiptImage!;
      await _uploadReceiptWithDeviceConflictRetry(
        receiptFile: receiptFile,
        packageId: packageId,
        paymentAmount: paymentAmount,
        referralCode: referralCode,
        recipientPhone: purchaseForSelf ? null : recipientPhone,
        recipientDevice: purchaseForSelf ? null : selectedRecipientDeviceId,
        device: device,
      );

      selectedPaymentMethod = null;
      selectedReceiptImage = null;
      referralCode = null;
      checkoutPackageId = null;
      amountToPay = null;
      _clearReferralPricing();
      referralTextController.clear();
      _resetGiftSelection();

      loadUserPayments();

      Get.offAllNamed(VIEWS.home.path);
      AppSnackbar.showSuccessAfterNav(
        'Success',
        'Payment submitted successfully! It will be reviewed by admin!',
        duration: const Duration(seconds: 4),
      );
      return true;
    } catch (e) {
      logger.e(e);
      AppSnackbar.showError(
        'Error',
        ApiErrorMessage.from(e, fallback: 'Failed to create payment'),
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
    _resetGiftSelection();
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
      AppSnackbar.showWarning(
        'Referral code',
        ApiErrorMessage.from(e, fallback: 'Could not validate referral code'),
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
      AppSnackbar.showWarning(
        'Referral code',
        ApiErrorMessage.from(e, fallback: 'Could not validate referral code'),
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
