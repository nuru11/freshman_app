import 'dart:io';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'api.dart';
import 'exceptions.dart';
import '../../utils/utils.dart';
import '../../models/agent.dart';
import '../../models/redemption.dart';

class AgentService extends GetxController {
  final ApiClient apiClient = ApiClient();

  /// Apply to be an agent
  ///
  /// [idDocumentPath] - Path to the ID document image file
  /// [bankName] - Optional bank name
  /// [bankAccountNumber] - Optional bank account number
  /// [accountName] - Optional account name
  Future<Agent> applyToBeAgent({
    required String idDocumentPath,
    String? bankName,
    String? bankAccountNumber,
    String? accountName,
  }) async {
    final file = File(idDocumentPath);
    if (!await file.exists()) {
      throw ApiException('ID document file does not exist');
    }

    final response = await apiClient.uploadFile(
      '/auth/agent/apply/',
      filePath: idDocumentPath,
      fieldName: 'id_document',
      additionalData: {
        if (bankName != null && bankName.isNotEmpty) 'bank_name': bankName,
        if (bankAccountNumber != null && bankAccountNumber.isNotEmpty)
          'bank_account_number': bankAccountNumber,
        if (accountName != null && accountName.isNotEmpty)
          'account_name': accountName,
      },
      authenticated: true,
    );

    if (response.statusCode == 201) {
      logger.i(response.data);
      return Agent.fromJson(response.data);
    }

    String? error;
    if (response.data['detail'] != null) {
      error = response.data['detail'];
    } else if (response.data['id_document'] != null) {
      error = "ID Document: ${response.data['id_document'][0]}";
    } else {
      error = "Failed to apply as agent";
    }

    logger.e(response.data);
    throw ApiException(error ?? "Failed to apply as agent");
  }

  /// Get agent status
  ///
  /// Returns the current agent status and coins
  /// Returns null if user has not applied to be an agent
  Future<Agent?> getAgentStatus() async {
    final response = await apiClient.get(
      '/auth/agent/status/',
      authenticated: true,
    );

    if (response.statusCode == 200) {
      logger.i(response.data);
      return Agent.fromJson(response.data);
    } else if (response.statusCode == 404) {
      // User has not applied to be an agent
      return null;
    }

    String? error;
    if (response.data['detail'] != null) {
      error = response.data['detail'];
    } else {
      error = "Failed to fetch agent status";
    }

    logger.e(response.data);
    throw ApiException(error ?? "Failed to fetch agent status");
  }

  /// Redeem all coins
  ///
  /// Returns the redemption response
  Future<Redemption> redeemCoins() async {
    final response = await apiClient.post(
      '/auth/agent/redemption/redeem/',
      data: {},
      authenticated: true,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      logger.i(response.data);
      return Redemption.fromJson(response.data);
    }

    String? error;
    if (response.data['detail'] != null) {
      error = response.data['detail'];
    } else {
      error = "Failed to redeem coins";
    }

    logger.e(response.data);
    throw ApiException(error ?? "Failed to redeem coins");
  }
}
