import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';

class DeviceService {
  final ApiClient apiClient = ApiClient();

  static String _safeField(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'unknown' : trimmed;
  }

  /// True when the backend rejected the id because another account owns it.
  static bool isOwnedByAnotherUser(Object error) {
    final message = ApiErrorMessage.from(error).toLowerCase();
    return message.contains('registered to another user');
  }

  Future<void> _postRegister(String phoneNumber) async {
    final device = await UserDevice.getDeviceInfo(phoneNumber);
    final response = await apiClient.post(
      '/auth/device/',
      data: {
        'device_id': device.id,
        'os': _safeField(device.os),
        'name': _safeField(device.name),
        'model': _safeField(device.model),
        'manufacturer': _safeField(device.manufacturer),
        'brand': _safeField(device.brand),
      },
      authenticated: true,
    );
    logger.i(response.data);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    }

    throw ApiException(
      ApiErrorMessage.fromData(response.data) ?? 'Failed to register device',
    );
  }

  /// Registers the current device. On ownership conflict, remints once and retries.
  Future<void> registerDevice(String phoneNumber) async {
    try {
      await _postRegister(phoneNumber);
    } catch (e) {
      if (!isOwnedByAnotherUser(e)) rethrow;

      logger.w('Device id owned by another user; reminting and retrying once');
      await UserDevice.remintDeviceId(phoneNumber);
      await _postRegister(phoneNumber);
    }
  }
}
