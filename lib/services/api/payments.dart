import 'package:get/get.dart';
import 'api.dart';
import 'exceptions.dart';
import '../../utils/utils.dart';
import '../../models/models.dart';
import 'dart:io';

class GiftRecipientDevice {
  final int id;
  final String name;
  final String brand;
  final String model;
  final String manufacturer;
  final String os;

  const GiftRecipientDevice({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.manufacturer,
    required this.os,
  });

  factory GiftRecipientDevice.fromJson(Map<String, dynamic> json) {
    return GiftRecipientDevice(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      manufacturer: (json['manufacturer'] ?? '').toString(),
      os: (json['os'] ?? '').toString(),
    );
  }

  String get label {
    final parts = [brand, model]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part.toLowerCase() != 'unknown')
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty && trimmedName.toLowerCase() != 'unknown') {
      return trimmedName;
    }
    return 'Device $id';
  }

  String get osLabel {
    final trimmed = os.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown') return '';
    return trimmed;
  }
}

class GiftRecipientLookup {
  final List<GiftRecipientDevice> devices;
  final int? gradeId;
  final String? gradeName;

  const GiftRecipientLookup({
    required this.devices,
    this.gradeId,
    this.gradeName,
  });

  factory GiftRecipientLookup.fromJson(Map<String, dynamic> json) {
    final rawDevices = json['devices'];
    final devices = rawDevices is List
        ? rawDevices
              .whereType<Map>()
              .map(
                (item) => GiftRecipientDevice.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <GiftRecipientDevice>[];
    final rawGrade = json['grade'];
    int? gradeId;
    String? gradeName;
    if (rawGrade is Map) {
      final id = rawGrade['id'];
      if (id is num) gradeId = id.toInt();
      final name = (rawGrade['name'] ?? '').toString().trim();
      if (name.isNotEmpty) gradeName = name;
    }
    return GiftRecipientLookup(
      devices: devices,
      gradeId: gradeId,
      gradeName: gradeName,
    );
  }
}

class PaymentService extends GetxController {
  final ApiClient apiClient = ApiClient();

  // Get all payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await apiClient.get(
        '/app/payment-methods/',
        authenticated: false,
      );

      logger.d(response.data);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        final paymentMethods = data
            .map((json) => PaymentMethod.fromJson(json))
            .toList();
        return paymentMethods;
      }

      throw ApiException(
        ApiErrorMessage.fromData(response.data) ??
            'Failed to load payment methods',
      );
    } catch (e) {
      logger.e('Error getting payment methods: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiErrorMessage.from(e, fallback: 'Failed to load payment methods'),
      );
    }
  }

  // Create a payment
  Future<Payment> createPayment(PaymentCreateRequest paymentRequest) async {
    try {
      final response = await apiClient.post(
        'app/payments/',
        data: paymentRequest.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payment = Payment.fromJson(response.data);
        return payment;
      }

      throw ApiException(
        ApiErrorMessage.fromData(response.data) ?? 'Failed to create payment',
      );
    } catch (e) {
      logger.e('Error creating payment: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiErrorMessage.from(e, fallback: 'Failed to create payment'),
      );
    }
  }

  // Get user's payments
  Future<List<Payment>> getUserPayments(String deviceId) async {
    try {
      final response = await apiClient.get(
        '/app/payments/',
        authenticated: true,
        queryParameters: {'device': deviceId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        final payments = data.map((json) => Payment.fromJson(json)).toList();
        return payments;
      }

      logger.e(response.data);

      throw ApiException(
        ApiErrorMessage.fromData(response.data) ?? 'Failed to load payments',
      );
    } catch (e) {
      logger.e('Error getting user payments: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiErrorMessage.from(e, fallback: 'Failed to load payments'),
      );
    }
  }

  Future<ReferralValidationResult> validateReferralCode({
    required String code,
    required int packageId,
  }) async {
    try {
      final response = await apiClient.get(
        '/app/referral/validate/',
        authenticated: true,
        queryParameters: {
          'code': code.trim().toUpperCase(),
          'package_id': packageId,
        },
      );

      if (response.statusCode == 200) {
        return ReferralValidationResult.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      throw ApiException(
        ApiErrorMessage.fromData(response.data) ??
            'Failed to validate referral code',
      );
    } catch (e) {
      logger.e('Error validating referral code: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiErrorMessage.from(e, fallback: 'Failed to validate referral code'),
      );
    }
  }

  Future<GiftRecipientLookup> lookupGiftRecipient(String phone) async {
    try {
      final response = await apiClient.get(
        '/app/gift-recipients/lookup/',
        authenticated: true,
        queryParameters: {'phone': phone},
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return GiftRecipientLookup.fromJson(data);
      }
      throw ApiException(
        ApiErrorMessage.fromData(response.data) ??
            'No active account is registered with that phone number.',
      );
    } catch (e) {
      logger.e('Error looking up gift recipient: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiErrorMessage.from(
          e,
          fallback: 'Could not look up that phone number.',
        ),
      );
    }
  }

  Future<Payment> uploadReceipt({
    required File file,
    required int package,
    required int paymentMethod,
    required String device,
    required double amount,
    String? referralCode,
    String? recipientPhone,
    int? recipientDevice,
  }) async {
    final deviceId = device.trim();
    if (deviceId.isEmpty) {
      throw ApiException('Device ID is missing. Please restart the app and try again.');
    }

    final additionalData = <String, dynamic>{
      'package': package,
      'method': paymentMethod,
      'device': deviceId,
      'amount': amount,
    };
    
    // Add referral_code if provided (convert to uppercase as per API spec)
    if (referralCode != null && referralCode.trim().isNotEmpty) {
      additionalData['referral_code'] = referralCode.trim().toUpperCase();
    }
    if (recipientPhone != null && recipientPhone.trim().isNotEmpty) {
      additionalData['recipient_phone'] = recipientPhone.trim();
    }
    if (recipientDevice != null) {
      additionalData['recipient_device'] = recipientDevice;
    }
    
    final response = await apiClient.postMultipart(
      '/app/payments/',
      file: file,
      additionalData: additionalData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      logger.d(response.data);
      final payment = Payment.fromJson(response.data);
      return payment;
    }
    logger.e(response.data);

    throw ApiException(
      ApiErrorMessage.fromData(response.data) ?? 'Failed to upload receipt',
    );
  }

  // Get all available packages
  Future<List<Package>> getPackages(String deviceId, {int? grade}) async {
    try {
      final queryParameters = <String, dynamic>{'device': deviceId};
      if (grade != null) {
        queryParameters['grade'] = grade;
      }
      final response = await apiClient.get(
        '/app/packages/',
        authenticated: true,
        queryParameters: queryParameters,
      );
      logger.d(response.data);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final packages = data.map((json) => Package.fromJson(json)).toList();
        return packages;
      }

      logger.e(response.data);

      throw ApiException(
        ApiErrorMessage.fromData(response.data) ?? 'Failed to load packages',
      );
    } catch (e) {
      logger.e('Error getting packages: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiErrorMessage.from(e, fallback: 'Failed to load packages'),
      );
    }
  }
}
