import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';

class AgentController extends GetxController {
  final AgentService _agentService = AgentService();
  final ImagePicker _picker = ImagePicker();

  // State variables
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isRedeeming = false;
  bool get isRedeeming => _isRedeeming;

  Agent? _agentStatus;
  Agent? get agentStatus => _agentStatus;

  File? _selectedIdDocument;
  File? get selectedIdDocument => _selectedIdDocument;

  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController bankAccountController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadAgentStatus();
  }

  @override
  void onClose() {
    bankNameController.dispose();
    bankAccountController.dispose();
    accountNameController.dispose();
    super.onClose();
  }

  /// Load agent status from API
  Future<void> loadAgentStatus() async {
    _isLoading = true;
    update();

    try {
      _agentStatus = await _agentService.getAgentStatus();
    } catch (e) {
      logger.e('Error loading agent status: $e');
      if (e is! ApiException || !e.message.contains('404')) {
        AppSnackbar.showError('Error', 'Failed to load agent status');
      }
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// Pick ID document from gallery
  Future<void> pickIdDocumentFromGallery({bool afterSheetDismissed = false}) async {
    final image = await ImagePickerPermissions.pickImage(
      picker: _picker,
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
      afterSheetDismissed: afterSheetDismissed,
    );

    if (image != null) {
      _selectedIdDocument = File(image.path);
      update();
    }
  }

  /// Pick ID document from camera
  Future<void> pickIdDocumentFromCamera({bool afterSheetDismissed = false}) async {
    final image = await ImagePickerPermissions.pickImage(
      picker: _picker,
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
      afterSheetDismissed: afterSheetDismissed,
    );

    if (image != null) {
      _selectedIdDocument = File(image.path);
      update();
    }
  }

  /// Clear selected ID document
  void clearSelectedDocument() {
    _selectedIdDocument = null;
    update();
  }

  /// Show image picker options
  Future<void> showImagePickerOptions() async {
    final cameraSupported = ImagePickerPermissions.supportsSource(
      _picker,
      ImageSource.camera,
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue[600]),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                pickIdDocumentFromGallery(afterSheetDismissed: true);
              },
            ),
            if (cameraSupported)
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue[600]),
                title: const Text('Take Photo'),
                onTap: () {
                  Get.back();
                  pickIdDocumentFromCamera(afterSheetDismissed: true);
                },
              ),
            if (_selectedIdDocument != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Get.back();
                  clearSelectedDocument();
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Submit agent application
  Future<void> submitApplication() async {
    if (_selectedIdDocument == null) {
      AppSnackbar.showError('Validation Error', 'Please select an ID document');
      return;
    }

    _isSubmitting = true;
    update();

    try {
      final agent = await _agentService.applyToBeAgent(
        idDocumentPath: _selectedIdDocument!.path,
        bankName: bankNameController.text.trim().isEmpty
            ? null
            : bankNameController.text.trim(),
        bankAccountNumber: bankAccountController.text.trim().isEmpty
            ? null
            : bankAccountController.text.trim(),
        accountName: accountNameController.text.trim().isEmpty
            ? null
            : accountNameController.text.trim(),
      );

      _agentStatus = agent;
      _selectedIdDocument = null;
      bankNameController.clear();
      bankAccountController.clear();
      accountNameController.clear();

      AppSnackbar.showSuccess(
        'Success',
        'Your application has been submitted successfully!',
      );

      // Navigate back or to status page
      Get.back();
      // Refresh status
      await loadAgentStatus();
    } on ApiException catch (e) {
      AppSnackbar.showError('Application Failed', e.message);
    } catch (e) {
      logger.e('Error submitting application: $e');
      AppSnackbar.showError(
        'Error',
        'Failed to submit application. Please try again.',
      );
    } finally {
      _isSubmitting = false;
      update();
    }
  }

  /// Check if user has already applied
  bool get hasApplied => _agentStatus != null;

  /// Check if user is approved
  bool get isApproved => _agentStatus?.isApproved ?? false;

  /// Check if user is rejected
  bool get isRejected => _agentStatus?.rejectedAt != null;

  /// Redeem all coins
  Future<void> redeemCoins() async {
    if (_agentStatus == null) {
      AppSnackbar.showError('Error', 'Agent status not found');
      return;
    }

    if (_agentStatus!.coins <= 0) {
      AppSnackbar.showError('No Coins', 'You don\'t have any coins to redeem');
      return;
    }

    _isRedeeming = true;
    update();

    try {
      final redemption = await _agentService.redeemCoins();

      AppSnackbar.showSuccess(
        'Redemption Request Submitted',
        '${redemption.coinsRedeemed} coins (${redemption.birrAmount} ETB) redemption request is ${redemption.status.displayName.toLowerCase()}.',
      );

      // Refresh status to get updated coin balance
      await loadAgentStatus();
    } on ApiException catch (e) {
      AppSnackbar.showError('Redemption Failed', e.message);
    } catch (e) {
      logger.e('Error redeeming coins: $e');
      AppSnackbar.showError(
        'Error',
        'Failed to redeem coins. Please try again.',
      );
    } finally {
      _isRedeeming = false;
      update();
    }
  }

  /// Show redeem coins dialog
  void showRedeemDialog() {
    if (_agentStatus == null || _agentStatus!.coins <= 0) {
      AppSnackbar.showError('No Coins', 'You don\'t have any coins to redeem');
      return;
    }

    Get.dialog(
      GetBuilder<AgentController>(
        builder: (controller) => AlertDialog(
          title: const Text('Redeem All Coins'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.blue[700],
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${controller.agentStatus!.coins}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'coins will be withdrawn',
                        style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All your coins will be withdrawn. Withdrawal requests will be reviewed by admin. if successful, you will receive the withdrawal amount in your bank account.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: controller.isRedeeming ? null : () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: controller.isRedeeming
                  ? null
                  : () {
                      Get.back();
                      controller.redeemCoins();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: controller.isRedeeming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Withdraw All'),
            ),
          ],
        ),
      ),
    );
  }
}
