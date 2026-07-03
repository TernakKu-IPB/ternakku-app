import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/core/repositories/base_repository.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository extends BaseRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      return await request(() async {
        final response = await _dio.post(
          ApiConstants.login,
          data: {
            "identifier": identifier,
            "password": password,
          },
        );
        
        return response.data;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        throw error.copyWith(
          fieldErrors: {
            'identifier': error.message,
            'password': error.message,
          },
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      return await request(() async {
        final response = await _dio.post(
          ApiConstants.register,
          data: {
            "fullName": fullName,
            "username": username,
            "email": email,
            "password": password,
            "confirmPassword": confirmPassword,
          },
        );
        
        return response.data; // Mengembalikan JSON 201 Created
      });
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        throw error.copyWith(
          fieldErrors: {
            'username': error.message,
            'email': error.message,
          },
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> logout() async {
    return request(() async {
      final response = await _dio.post(
        ApiConstants.logout,
      );
      return response.data;
    });
  }

  Future<Map<String, dynamic>> verifyEmail(String otpCode) async {
    return request(() async {
      final response = await _dio.post(
        ApiConstants.verifyEmail,
        data: {"otpCode": otpCode},
      );
      return response.data;
    });
  }

  Future<Map<String, dynamic>> resendVerification() async {
    return request(() async {
      final response = await _dio.post(ApiConstants.resendVerification);
      return response.data;
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    return request(() async {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {"identifier": identifier},
      );
      return response.data;
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return request(() async {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {
          "token": token,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        },
      );
      return response.data;
    });
  }
}