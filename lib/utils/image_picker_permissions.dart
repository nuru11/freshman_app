import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_academy/utils/snackbar_utils.dart';
import 'package:vector_academy/utils/utils.dart';

/// Requests OS permission and picks an image via [image_picker].
class ImagePickerPermissions {
  ImagePickerPermissions._();

  static Future<bool> ensurePermission(ImageSource source) async {
    if (kIsWeb) return true;

    // iOS 14+ uses PHPicker for gallery; no prior photo permission needed.
    if (Platform.isIOS && source == ImageSource.gallery) return true;

    final permission = _permissionForSource(source);
    if (permission == null) return true;

    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      AppSnackbar.showError(
        'Permission required',
        source == ImageSource.camera
            ? 'Enable camera access in Settings to take a photo.'
            : 'Enable photo library access in Settings to choose a picture.',
      );
    } else {
      AppSnackbar.showError(
        'Permission required',
        source == ImageSource.camera
            ? 'Camera access is needed to take a photo.'
            : 'Photo library access is needed to choose a picture.',
      );
    }
    return false;
  }

  static Permission? _permissionForSource(ImageSource source) {
    if (!Platform.isIOS && !Platform.isAndroid) return null;

    switch (source) {
      case ImageSource.camera:
        return Permission.camera;
      case ImageSource.gallery:
        return Permission.photos;
    }
  }

  /// Picks an image after permission check. Use [afterSheetDismissed] when
  /// calling right after closing a bottom sheet (helps iPad presentation).
  static Future<XFile?> pickImage({
    required ImagePicker picker,
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool afterSheetDismissed = false,
  }) async {
    if (!await ensurePermission(source)) return null;

    if (afterSheetDismissed && Platform.isIOS) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    try {
      return await picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } catch (e, st) {
      logger.e('pickImage failed', error: e, stackTrace: st);
      AppSnackbar.showError(
        'Error',
        source == ImageSource.camera
            ? 'Failed to take photo'
            : 'Failed to pick image',
      );
      return null;
    }
  }

  /// Whether the device can use [source] (e.g. camera on simulator).
  static bool supportsSource(ImagePicker picker, ImageSource source) {
    try {
      return picker.supportsImageSource(source);
    } catch (_) {
      return true;
    }
  }
}
