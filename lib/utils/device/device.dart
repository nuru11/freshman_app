import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';

class DeviceInfo {
  String id;
  String brand;
  String model;
  String manufacturer;
  String device;
  String name;
  String os;

  DeviceInfo({
    required this.id,
    required this.brand,
    required this.model,
    required this.manufacturer,
    required this.device,
    required this.name,
    required this.os,
  });
}

class UserDevice {
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  static String getAndroidVersion() {
    return '1.0.0';
  }

  static Future<DeviceInfo> getDeviceInfo(String phoneNumber) async {
    final deviceId = await deviceHash(phoneNumber);
    final df = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await df.androidInfo;
      return DeviceInfo(
        id: deviceId,
        brand: androidInfo.brand,
        model: androidInfo.model,
        manufacturer: androidInfo.manufacturer,
        name: androidInfo.name,
        device: androidInfo.device,
        os: 'android',
      );
    } else if (Platform.isIOS) {
      final iosInfo = await df.iosInfo;
      return DeviceInfo(
        id: deviceId,
        brand: iosInfo.model,
        model: iosInfo.name,
        manufacturer: iosInfo.systemVersion,
        name: iosInfo.name,
        device: iosInfo.systemName,
        os: 'ios',
      );
    } else if (Platform.isWindows) {
      final windowsInfo = await df.windowsInfo;
      return DeviceInfo(
        id: deviceId,
        brand: windowsInfo.computerName,
        model: windowsInfo.productId,
        manufacturer: windowsInfo.deviceId,
        name: windowsInfo.productName,
        device: windowsInfo.deviceId,
        os: 'windows',
      );
    } else if (Platform.isMacOS) {
      final macosInfo = await df.macOsInfo;
      return DeviceInfo(
        id: deviceId,
        brand: macosInfo.model,
        model: macosInfo.modelName,
        manufacturer: macosInfo.arch,
        name: macosInfo.modelName,
        device: macosInfo.modelName,
        os: 'macos',
      );
    } else if (Platform.isLinux) {
      final linuxInfo = await df.linuxInfo;
      return DeviceInfo(
        id: deviceId,
        brand: linuxInfo.name,
        model: linuxInfo.version ?? '',
        manufacturer: linuxInfo.id,
        name: linuxInfo.name,
        device: linuxInfo.name,
        os: 'linux',
      );
    }

    return DeviceInfo(
      id: 'Unknown',
      brand: 'Unknown',
      model: 'Unknown',
      manufacturer: 'Unknown',
      device: 'Unknown',
      name: 'Unknown',
      os: 'Unknown',
    );
  }

  static Future<String> _deviceId(String phoneNumber) async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;

      return "${androidInfo.brand} ${androidInfo.model} ${androidInfo.manufacturer} ${androidInfo.board} ${androidInfo.device} ${androidInfo.name} ${androidInfo.id} $phoneNumber";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return "${iosInfo.model} ${iosInfo.name} ${iosInfo.systemVersion}";
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return "${windowsInfo.numberOfCores} ${windowsInfo.productId} ${windowsInfo.deviceId}";
    } else if (Platform.isMacOS) {
      final macosInfo = await deviceInfo.macOsInfo;
      return "${macosInfo.model} ${macosInfo.modelName} ${macosInfo.arch}";
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return "${linuxInfo.name} ${linuxInfo.version} ${linuxInfo.id}";
    }
    return '1.0.0';
  }

  static Future<String> deviceHash(String phoneNumber) async {
    final raw = await _deviceId(phoneNumber);
    return sha256.convert(raw.codeUnits).toString();
  }
}
