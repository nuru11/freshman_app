import 'package:get/get.dart';
import 'api.dart';
import 'exceptions.dart';
import '../../utils/utils.dart';

import '../../models/user.dart';

class UserService extends GetxController {
  final ApiClient apiClient = ApiClient();

  Future<User> getUser() async {
    final response = await apiClient.get('/auth/me', authenticated: true);
    if (response.statusCode == 200) {
      return User.fromJson(response.data);
    }
    throw ApiException(response.data['detail'] ?? "Failed to get user");
  }

  Future<bool> deleteUser() async {
    final response = await apiClient.delete(
      '/auth/me/delete-account/',
      authenticated: true,
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw ApiException(response.data['detail'] ?? "Failed to delete user");
  }

  Future<RegisterResponse> registerUser(
    String name,
    String phone,
    String password,
    int grade,
  ) async {
    name = name.trim();
    final lastName = name.split(' ').lastOrNull;
    final firstName = name.split(' ').first;
    final data = {
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phone,
      'password': password,
      'gradeId': grade,
    };
    
    final response = await apiClient.post(
      '/auth/register/',
      data: data,
    );

    if (response.statusCode == 201) {
      logger.i(response.data);
      return RegisterResponse.fromJson(response.data);
    }
    String? error;
    if (response.data['phone_number'] != null) {
      error = "Phone Number: ${response.data['phone_number'][0]}";
    }
    if (response.data['grade'] != null) {
      error = "Grade: ${response.data['grade'][0]}";
    }
    if (response.data['password'] != null) {
      error = "Password: ${response.data['password'][0]}";
    }
    if (response.data['first_name'] != null) {
      error = "First Name: ${response.data['first_name'][0]}";
    }
    if (response.data['last_name'] != null) {
      error = "Last Name: ${response.data['last_name'][0]}";
    }
    logger.e(response.data);
    throw ApiException(error ?? "Failed to register user");
  }

  Future<AuthResponse> loginUser(String phone, String password) async {
    final response = await apiClient.post(
      '/auth/login/',
      data: {'phone_number': phone, 'password': password},
    );
    if (response.statusCode == 200) {
      logger.i(response.data);

      return AuthResponse.fromJson(response.data);
    }

    logger.e(response.data);

    throw ApiException(response.data['detail'] ?? "Failed to login user");
  }

  Future<User> updateUser({
    required String phoneNumber,
    required String name,
    required int grade,
    String? profilePicturePath,
  }) async {
    final firstName = name.split(' ').first;
    final lastName = name.replaceAll(firstName, '').trim();
    logger.i(grade);

    // If profile picture is provided, use multipart upload
    if (profilePicturePath != null) {
      final response = await apiClient.uploadFile(
        '/auth/me/update/',
        filePath: profilePicturePath,
        method: 'PATCH',
        fieldName: 'profile_pic',
        additionalData: {
          'phone_number': phoneNumber,
          'first_name': firstName,
          'last_name': lastName,
          'grade_id': grade,
        },
        authenticated: true,
      );
      logger.i(response.data);
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      throw ApiException(response.data['detail'] ?? "Failed to update user");
    }

    // Otherwise, use regular PATCH request
    final response = await apiClient.patch(
      '/auth/me/update/',
      data: {
        'phone_number': phoneNumber,
        'first_name': firstName,
        'last_name': lastName,
        'grade_id': grade,
      },
      authenticated: true,
    );
    logger.i(response.data);
    if (response.statusCode == 200) {
      return User.fromJson(response.data);
    }
    throw ApiException(response.data['detail'] ?? "Failed to update user");
  }

  Future<VerifyPhoneResponse> verifyPhone(String phone, String otp) async {
    final response = await apiClient.post(
      '/auth/verify-otp/',
      data: {'phone_number': phone, 'otp': otp},
    );
    // return VerifyPhoneResponse.fromJson(response.data);
    if (response.statusCode == 200) {
      // apiClient.setTokens(response.data['jwt'], response.data['jwt']);
      logger.i(response.data);
      return VerifyPhoneResponse.fromJson(response.data);
    }
    logger.e(response.data);
    throw ApiException(response.data['detail'] ?? "Failed to verify phone");
  }

  Future<User> uploadProfilePicture(String filePath) async {
    final response = await apiClient.uploadFile(
      '/auth/me/update/',
      filePath: filePath,
      method: 'PATCH',
      fieldName: 'profile_pic',
      authenticated: true,
    );
    logger.i(response.data);
    if (response.statusCode == 200) {
      return User.fromJson(response.data);
    }
    throw ApiException(
      response.data['detail'] ?? "Failed to upload profile picture",
    );
  }
}
