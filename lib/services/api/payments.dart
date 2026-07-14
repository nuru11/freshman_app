import 'package:get/get.dart';
import 'api.dart';
import 'exceptions.dart';
import '../../utils/utils.dart';
import '../../models/models.dart';
import 'dart:io';

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

      throw ApiException('Failed to load payment methods');
    } catch (e) {
      logger.e('Error getting payment methods: $e');
      throw ApiException('Failed to load payment methods');
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
        response.data['error']?['message'] ?? 'Failed to create payment',
      );
    } catch (e) {
      logger.e('Error creating payment: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create payment');
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

      throw ApiException('Failed to load payments');
    } catch (e) {
      logger.e('Error getting user payments: $e');
      throw ApiException('Failed to load payments');
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

      throw ApiException('Failed to validate referral code');
    } catch (e) {
      logger.e('Error validating referral code: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to validate referral code');
    }
  }

  Future<Payment> uploadReceipt({
    required File file,
    required int package,
    required int paymentMethod,
    required String device,
    required double amount,
    String? referralCode,
  }) async {
    final additionalData = <String, dynamic>{
      'package': package,
      'method': paymentMethod,
      'device': device,
      'amount': amount,
    };
    
    // Add referral_code if provided (convert to uppercase as per API spec)
    if (referralCode != null && referralCode.trim().isNotEmpty) {
      additionalData['referral_code'] = referralCode.trim().toUpperCase();
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

    throw ApiException('Failed to upload receipt');
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

      throw ApiException('Failed to load packages');
    } catch (e) {
      logger.e('Error getting packages: $e');
      throw ApiException('Failed to load packages');
    }
  }
}
