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

  Future<void> registerDevice(String phoneNumber) async {
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

    throw ApiException("Failed to register device");
  }
}
