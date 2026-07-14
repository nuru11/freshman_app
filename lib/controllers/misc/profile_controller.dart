import 'package:vector_academy/utils/storages/storages.dart';
import 'package:get/get.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/models/models.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'dart:async';
import 'dart:io';
import 'package:vector_academy/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool isUpdating = false;
  bool hasChangeOnEditProfile = false;

  final AuthService _authService = Get.find<AuthService>();

  final phoneEditController = TextEditingController();
  final nameEditController = TextEditingController();
  User? _user;
  User? get user => _user;
  String get fullName => "${_user?.firstName} ${_user?.lastName ?? ''}";

  late StreamSubscription<InternetStatus> _internetStatusSubscription;

  List<Grade> _availableGrades = [];
  List<Grade> get availableGrades => _availableGrades;

  Grade? _selectedGrade;
  Grade? get selectedGrade => _selectedGrade;

  Grade? _currentGrade;
  Grade? get currentGrade => _currentGrade;

  bool _isDeletingAccount = false;
  bool get isDeletingAccount => _isDeletingAccount;

  final TextEditingController _deleteConfirmationController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedProfileImage;
  File? get selectedProfileImage => _selectedProfileImage;
  bool _isUploadingProfilePicture = false;
  bool get isUploadingProfilePicture => _isUploadingProfilePicture;

  @override
  void onInit() async {
    super.onInit();

    _user = await HiveUserStorage().getUser();

    loadUserData();

    loadGrades();

    _authService.listenUser((event) {
      _user = event;
      update();
    });

    _internetStatusSubscription = InternetConnection().onStatusChange.listen((
      event,
    ) {
      if (event == InternetStatus.connected) {
        loadUserData();
        loadGrades();
      }
    });
  }

  @override
  void onClose() {
    _internetStatusSubscription.cancel();
    phoneEditController.dispose();
    nameEditController.dispose();
    _deleteConfirmationController.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    _isLoading = true;
    update();

    try {
      final user_ = await UserService().getUser();

      await AuthService().saveUser(user_);
    } catch (e) {
      logger.e(e);
    } finally {
      _isLoading = false;
      update();
    }
    phoneEditController.text = user?.phoneNumber ?? '';
    nameEditController.text = fullName;

    _currentGrade = user?.grade;

    _isLoading = false;
    update();
  }

  Future<void> loadGrades() async {
    try {
      final gradeService = Get.find<GradeService>();
      _availableGrades = await gradeService.getGrades(backendAppPackage);
      _selectedGrade = user?.grade;
      update();
    } catch (e) {
      logger.e(e);
    }
  }

  void updateUserName(String name) {
    if (name.trim() != fullName) {
      hasChangeOnEditProfile = true;
    }
    update();
  }

  void updateUserPhone(String phone) {
    if (phone.trim() != user?.phoneNumber) {
      hasChangeOnEditProfile = true;
    }
    update();
  }

  void updateSelectedGrade(int? grade) {
    _selectedGrade = _availableGrades.firstWhere(
      (element) => element.id == grade,
    );
    logger.i('Changed grade to ${_selectedGrade?.name}');
    if (_selectedGrade != user?.grade) {
      hasChangeOnEditProfile = true;
    }

    update();
  }

  void updateUserOnSave() async {
    if (isUpdating) return;
    isUpdating = true;
    update();
    try {
      // Update user with profile picture in a single request if selected
      final user_ = await UserService().updateUser(
        phoneNumber: phoneEditController.text.trim(),
        name: nameEditController.text.trim(),
        grade: _selectedGrade?.id ?? 0,
        profilePicturePath: _selectedProfileImage?.path,
      );
      await AuthService().saveUser(user_);
      hasChangeOnEditProfile = false;
      _selectedProfileImage = null;
    } catch (e) {
      logger.e(e);
      AppSnackbar.showError('Error', 'Failed to update user');
    } finally {
      _selectedGrade = user?.grade;
      _isLoading = false;
      isUpdating = false;
      phoneEditController.text = user?.phoneNumber ?? '';
      nameEditController.text = fullName;
      update();
      Get.back();
    }
  }

  Future<void> pickProfileImageFromGallery({bool afterSheetDismissed = false}) async {
    final image = await ImagePickerPermissions.pickImage(
      picker: _picker,
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      afterSheetDismissed: afterSheetDismissed,
    );

    if (image != null) {
      _selectedProfileImage = File(image.path);
      hasChangeOnEditProfile = true;
      update();
    }
  }

  Future<void> pickProfileImageFromCamera({bool afterSheetDismissed = false}) async {
    final image = await ImagePickerPermissions.pickImage(
      picker: _picker,
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      afterSheetDismissed: afterSheetDismissed,
    );

    if (image != null) {
      _selectedProfileImage = File(image.path);
      hasChangeOnEditProfile = true;
      update();
    }
  }

  Future<void> showProfileImagePickerOptions() async {
    final cameraSupported = ImagePickerPermissions.supportsSource(
      _picker,
      ImageSource.camera,
    );

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue[600]),
              title: Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                pickProfileImageFromGallery(afterSheetDismissed: true);
              },
            ),
            if (cameraSupported)
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue[600]),
                title: Text('Take Photo'),
                onTap: () {
                  Get.back();
                  pickProfileImageFromCamera(afterSheetDismissed: true);
                },
              ),
            if (_selectedProfileImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove Photo'),
                onTap: () {
                  Get.back();
                  _selectedProfileImage = null;
                  hasChangeOnEditProfile = true;
                  update();
                },
              ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> uploadProfilePicture() async {
    if (_selectedProfileImage == null) return;

    _isUploadingProfilePicture = true;
    update();

    try {
      final user_ = await UserService().uploadProfilePicture(
        _selectedProfileImage!.path,
      );
      await AuthService().saveUser(user_);
      _selectedProfileImage = null;
      AppSnackbar.showSuccess('Success', 'Profile picture updated');
    } catch (e) {
      logger.e(e);
      AppSnackbar.showError('Error', 'Failed to upload profile picture');
      rethrow;
    } finally {
      _isUploadingProfilePicture = false;
      update();
    }
  }

  void navigateToEditProfile() {
    Get.toNamed('/edit-profile');
  }

  void openSupport() {
    Get.toNamed(VIEWS.support.path);
  }

  void openAppInfo() {
    Get.toNamed(VIEWS.about.path);
  }

  void logout() {
    // Navigate to login and clear navigation stack
    Get.offAllNamed(VIEWS.login.path);
    // Logout from the auth service
    AuthService().logout();
  }

  void showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This action will permanently delete:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            _buildDeleteWarningItem('• Your profile and personal information'),
            _buildDeleteWarningItem('• All your exam progress and scores'),
            _buildDeleteWarningItem('• Downloaded content and notes'),
            _buildDeleteWarningItem('• Account settings and preferences'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          TextButton(
            onPressed: _isDeletingAccount
                ? null
                : () => _confirmDeleteAccount(),
            child: _isDeletingAccount
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red[600]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }

  void _confirmDeleteAccount() {
    Get.back(); // Close the first dialog

    Get.dialog(
      GetBuilder<ProfileController>(
        builder: (controller) {
          return AlertDialog(
            title: Text(
              'Final Confirmation',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[600],
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Type "DELETE" to confirm account deletion:',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _deleteConfirmationController,
                  decoration: InputDecoration(
                    hintText: 'Type DELETE here',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red[600]!),
                    ),
                  ),
                  onChanged: (value) => update(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _deleteConfirmationController.clear();
                  Get.back();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    _deleteConfirmationController.text.trim() == 'DELETE' &&
                        !_isDeletingAccount
                    ? () => _deleteAccount()
                    : null,
                child: _isDeletingAccount
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Delete Forever',
                        style: TextStyle(
                          color:
                              _deleteConfirmationController.text.trim() ==
                                  'DELETE'
                              ? Colors.red[600]
                              : Colors.grey[400],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;

    _isDeletingAccount = true;
    update();

    try {
      // Call the delete user API
      await UserService().deleteUser();

      // Clear all local data
      await _clearAllLocalData();

      Get.back(); // Close the confirmation dialog

      // Show success message
      AppSnackbar.showSuccess(
        'Account Deleted',
        'Your account has been permanently deleted',
        duration: Duration(seconds: 3),
      );

      // Navigate to login and clear all routes
      Get.offAllNamed(VIEWS.login.path);
    } catch (e) {
      logger.e('Error deleting account: $e');

      Get.back(); // Close the confirmation dialog

      AppSnackbar.showError(
        'Error',
        'Failed to delete account: ${e.toString()}',
        duration: Duration(seconds: 5),
      );
    } finally {
      _deleteConfirmationController.clear();
      _isDeletingAccount = false;
      update();
    }
  }

  Future<void> _clearAllLocalData() async {
    try {
      // Clear authentication data
      await _authService.logout();

      await HiveSubjectsStorage().clear();
      await HiveChaptersStorage().clear();
      await HiveAuthStorage().clear();
      await HiveUserStorage().clear();
      await HiveExamStorage().clear();
      await HiveQuizzesStorage().clear();
      await HiveNoteStorage().clear();
      await HiveVideoStorage().clear();

      // Clear any other local storage if available
      // You might want to add more clearing logic here based on your app's needs

      logger.i('All local data cleared after account deletion');
    } catch (e) {
      logger.e('Error clearing local data: $e');
    }
  }
}
