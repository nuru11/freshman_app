import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/utils/device/device.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/utils/utils.dart';

class DeviceService {
  final ApiClient apiClient = ApiClient();

  Future<void> registerDevice(String phoneNumber) async {
    final device = await UserDevice.getDeviceInfo(phoneNumber);
    final response = await apiClient.post(
      '/auth/device/',
      data: {
        'device_id': device.id,
        'os': device.os,
        'name': device.name,
        'model': device.model,
        'manufacturer': device.manufacturer,
        'device': device.device,
        'brand': device.brand,
      },

      authenticated: true,
    );
    logger.i(response.data);
    if (response.statusCode == 201) {
      return;
    }

    throw ApiException("Failed to register device");
  }
}
