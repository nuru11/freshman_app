import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:vector_academy/utils/storages/device.dart';
import 'package:vector_academy/utils/utils.dart';

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
  static final HiveDeviceStorage _storage = HiveDeviceStorage();
  static const AndroidId _androidIdPlugin = AndroidId();

  static DeviceInfo? _cached;

  static const String _unknown = 'unknown';

  static String getAndroidVersion() {
    return '1.0.0';
  }

  static String _safe(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? _unknown : trimmed;
  }

  static String _hash(String raw) {
    return sha256.convert(raw.codeUnits).toString();
  }

  /// Resolves a stable install id:
  /// 1) Hive (survives One UI / OS updates once written)
  /// 2) Legacy Build hash (keeps existing paid entitlements)
  /// 3) ANDROID_ID / IDFV (stable across OS updates)
  /// 4) Random fallback
  static Future<DeviceInfo> getDeviceInfo(String phoneNumber) async {
    if (_cached != null) {
      return _cached!;
    }

    final storedId = await _storage.getDeviceId();
    final metadata = await _readMetadataOnly();

    late final String resolvedId;

    if (storedId != null && storedId.isNotEmpty) {
      // Never re-hash Build fields once we have a persisted id.
      resolvedId = storedId;
    } else {
      resolvedId = await _resolveNewDeviceId(phoneNumber);
      await _storage.setDeviceId(resolvedId);
    }

    final info = DeviceInfo(
      id: resolvedId,
      brand: metadata.brand,
      model: metadata.model,
      manufacturer: metadata.manufacturer,
      device: metadata.device,
      name: metadata.name,
      os: metadata.os,
    );

    _cached = info;
    return info;
  }

  static Future<String> _resolveNewDeviceId(String phoneNumber) async {
    // Prefer legacy hash so users who have not OS-updated keep access.
    try {
      final legacy = await deviceHash(phoneNumber);
      if (legacy.isNotEmpty && legacy != 'Unknown') {
        return legacy;
      }
    } catch (e, st) {
      logger.w('Legacy device hash failed: $e\n$st');
    }

    try {
      final stable = await _stablePlatformId();
      if (stable != null && stable.isNotEmpty) {
        return _hash(stable);
      }
    } catch (e, st) {
      logger.w('Stable platform id failed: $e\n$st');
    }

    return _generateFallbackId(phoneNumber);
  }

  /// ANDROID_ID (Android) / identifierForVendor (iOS) — survive OS updates.
  /// Prefixed with [backendAppPackage] so each product app gets a distinct id.
  static Future<String?> _stablePlatformId() async {
    if (Platform.isAndroid) {
      final id = await _androidIdPlugin.getId();
      if (id != null && id.trim().isNotEmpty) {
        return '${backendAppPackage}:${id.trim()}';
      }
      return null;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final idfv = iosInfo.identifierForVendor;
      if (idfv != null && idfv.trim().isNotEmpty) {
        return '${backendAppPackage}:${idfv.trim()}';
      }
      return null;
    }
    return null;
  }

  /// Metadata only — must not be used for entitlement id after Hive is set.
  static Future<DeviceInfo> _readMetadataOnly() async {
    try {
      final df = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await df.androidInfo;
        return DeviceInfo(
          id: '',
          brand: _safe(androidInfo.brand),
          model: _safe(androidInfo.model),
          manufacturer: _safe(androidInfo.manufacturer),
          name: _safe(androidInfo.name),
          device: _safe(androidInfo.device),
          os: 'android',
        );
      } else if (Platform.isIOS) {
        final iosInfo = await df.iosInfo;
        return DeviceInfo(
          id: '',
          brand: _safe(iosInfo.model),
          model: _safe(iosInfo.name),
          manufacturer: _safe(iosInfo.systemVersion),
          name: _safe(iosInfo.name),
          device: _safe(iosInfo.systemName),
          os: 'ios',
        );
      } else if (Platform.isWindows) {
        final windowsInfo = await df.windowsInfo;
        return DeviceInfo(
          id: '',
          brand: _safe(windowsInfo.computerName),
          model: _safe(windowsInfo.productId),
          manufacturer: _safe(windowsInfo.deviceId),
          name: _safe(windowsInfo.productName),
          device: _safe(windowsInfo.deviceId),
          os: 'windows',
        );
      } else if (Platform.isMacOS) {
        final macosInfo = await df.macOsInfo;
        return DeviceInfo(
          id: '',
          brand: _safe(macosInfo.model),
          model: _safe(macosInfo.modelName),
          manufacturer: _safe(macosInfo.arch),
          name: _safe(macosInfo.modelName),
          device: _safe(macosInfo.modelName),
          os: 'macos',
        );
      } else if (Platform.isLinux) {
        final linuxInfo = await df.linuxInfo;
        return DeviceInfo(
          id: '',
          brand: _safe(linuxInfo.name),
          model: _safe(linuxInfo.version),
          manufacturer: _safe(linuxInfo.id),
          name: _safe(linuxInfo.name),
          device: _safe(linuxInfo.name),
          os: 'linux',
        );
      }
    } catch (e, st) {
      logger.w('Failed to read device metadata: $e\n$st');
    }

    return DeviceInfo(
      id: '',
      brand: _unknown,
      model: _unknown,
      manufacturer: _unknown,
      device: _unknown,
      name: _unknown,
      os: Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : _unknown,
    );
  }

  /// Legacy fingerprint — only used when Hive has no id yet.
  static Future<String> _legacyRawDeviceId(String phoneNumber) async {
    final package = backendAppPackage;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return "$package ${androidInfo.brand} ${androidInfo.model} ${androidInfo.manufacturer} ${androidInfo.board} ${androidInfo.device} ${androidInfo.name} ${androidInfo.id} $phoneNumber";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return "$package ${iosInfo.model} ${iosInfo.name} ${iosInfo.systemVersion}";
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return "$package ${windowsInfo.numberOfCores} ${windowsInfo.productId} ${windowsInfo.deviceId}";
    } else if (Platform.isMacOS) {
      final macosInfo = await deviceInfo.macOsInfo;
      return "$package ${macosInfo.model} ${macosInfo.modelName} ${macosInfo.arch}";
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return "$package ${linuxInfo.name} ${linuxInfo.version} ${linuxInfo.id}";
    }
    return '$package:1.0.0';
  }

  static Future<String> deviceHash(String phoneNumber) async {
    final raw = await _legacyRawDeviceId(phoneNumber);
    return _hash(raw);
  }

  static String _generateFallbackId(String phoneNumber) {
    final random = Random.secure();
    final entropy = List<int>.generate(32, (_) => random.nextInt(256));
    final raw =
        '${backendAppPackage}_${phoneNumber}_${DateTime.now().microsecondsSinceEpoch}_${entropy.join(',')}';
    return _hash(raw);
  }
}
