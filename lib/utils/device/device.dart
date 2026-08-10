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
  static String? _cachedForPhone;

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
  /// 1) Hive (survives OS updates once written)
  /// 2) Platform-specific new id (see [_resolveNewDeviceId])
  static Future<DeviceInfo> getDeviceInfo(String phoneNumber) async {
    if (_cached != null && _cachedForPhone == phoneNumber) {
      return _cached!;
    }

    final storedId = await _storage.getDeviceId();
    final metadata = await _readMetadataOnly();

    late final String resolvedId;

    if (storedId != null && storedId.isNotEmpty) {
      resolvedId = await _maybeMigrateStoredId(storedId, phoneNumber);
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
    _cachedForPhone = phoneNumber;
    return info;
  }

  /// On iOS, replace colliding legacy name/model/OS hashes with phone-scoped IDFV.
  static Future<String> _maybeMigrateStoredId(
    String storedId,
    String phoneNumber,
  ) async {
    if (!Platform.isIOS) {
      return storedId;
    }

    try {
      final legacy = await deviceHash(phoneNumber);
      if (storedId == legacy) {
        final migrated = await _resolveNewDeviceId(phoneNumber);
        await _storage.setDeviceId(migrated);
        logger.i('Migrated legacy iOS device id to phone-scoped IDFV');
        return migrated;
      }
    } catch (e, st) {
      logger.w('Legacy iOS device id migration failed: $e\n$st');
    }
    return storedId;
  }

  /// Clears persisted/cached id and mints a new unique one (collision recovery).
  /// Always uses a secure random id — never IDFV/legacy — so a taken IDFV cannot
  /// be re-selected on the same phone.
  static Future<DeviceInfo> remintDeviceId(String phoneNumber) async {
    _cached = null;
    _cachedForPhone = null;
    await _storage.clear();

    final metadata = await _readMetadataOnly();
    final resolvedId = _generateFallbackId(phoneNumber);
    await _storage.setDeviceId(resolvedId);

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
    _cachedForPhone = phoneNumber;
    logger.i('Reminted device id (previous was conflicting)');
    return info;
  }

  /// Android: legacy hash first (keeps paid unlocks), then ANDROID_ID, then random.
  /// iOS: phone-scoped IDFV first (legacy name/model/OS hash collides across phones).
  static Future<String> _resolveNewDeviceId(
    String phoneNumber, {
    String? excludeId,
  }) async {
    Future<String?> tryId(Future<String?> Function() resolve) async {
      try {
        final id = await resolve();
        if (id == null || id.isEmpty || id == 'Unknown') return null;
        if (excludeId != null && excludeId.isNotEmpty && id == excludeId) {
          return null;
        }
        return id;
      } catch (e, st) {
        logger.w('Device id candidate failed: $e\n$st');
        return null;
      }
    }

    if (Platform.isIOS) {
      final fromIdfv = await tryId(() async {
        final stable = await _stablePlatformId(phoneNumber);
        if (stable == null || stable.isEmpty) return null;
        return _hash(stable);
      });
      if (fromIdfv != null) return fromIdfv;
      return _generateFallbackId(phoneNumber);
    }

    // Android (and other): prefer legacy so existing entitlements keep working.
    final fromLegacy = await tryId(() async {
      final legacy = await deviceHash(phoneNumber);
      if (legacy.isEmpty || legacy == 'Unknown') return null;
      return legacy;
    });
    if (fromLegacy != null) return fromLegacy;

    final fromStable = await tryId(() async {
      final stable = await _stablePlatformId(phoneNumber);
      if (stable == null || stable.isEmpty) return null;
      return _hash(stable);
    });
    if (fromStable != null) return fromStable;

    return _generateFallbackId(phoneNumber);
  }

  /// ANDROID_ID (Android) / identifierForVendor+phone (iOS) — survive OS updates.
  /// Prefixed with [backendAppPackage] so each product app gets a distinct id.
  /// iOS includes phone so two accounts on one device do not share a device_id.
  static Future<String?> _stablePlatformId(String phoneNumber) async {
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
        return '${backendAppPackage}:${idfv.trim()}:${phoneNumber.trim()}';
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

  /// Legacy fingerprint — only used when Hive has no id yet (Android), or to
  /// detect stale iOS Hive values for migration.
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
