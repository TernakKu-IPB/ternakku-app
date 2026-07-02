import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/user_model.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          "identifier": identifier,
          "password": password,
        },
      );
      
      return response.data; // Mengembalikan JSON 200
    } on DioException catch (e) {
      var error = _parseDioError(e);

      if (error.statusCode == 404) {
        error = error.copyWith(
          fieldErrors: {
            'identifier': error.message,
            'password': error.message,
          },
        );
      }

      throw error;
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
    } on DioException catch (e) {
      var error = _parseDioError(e);

      if (error.statusCode == 409) {
        error = error.copyWith(
          fieldErrors: {
            'username': error.message,
            'email': error.message,
          },
        );
      }

      throw error;
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _dio.post(
        ApiConstants.logout,
      );
      
      return response.data; // Mengembalikan JSON 200
    } on DioException catch (e) {
      var error = _parseDioError(e);
      throw error;
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String otpCode) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyEmail,
        data: {"otpCode": otpCode},
      );
      return response.data;
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<Map<String, dynamic>> resendVerification() async {
    try {
      final response = await _dio.post(ApiConstants.resendVerification);
      return response.data;
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.getProfile);
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  ApiException _parseDioError(DioException e) {
    if (e.response == null || e.response?.data == null) {
      return ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        statusCode: 500,
        fieldErrors: {},
      );
    }

    final errorData = e.response!.data;

    final statusCode =
        errorData['statusCode'] ?? e.response!.statusCode ?? 500;

    final message =
        errorData['message'] ?? 'Terjadi kesalahan pada server';

    final fieldErrors = <String, String>{};

    if (statusCode == 400 && errorData['error'] is List) {
      for (final err in errorData['error']) {
        if (err['path'] is List && err['path'].isNotEmpty) {
          fieldErrors[err['path'][0].toString()] =
              err['message']?.toString() ?? 'Input tidak valid';
        }
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }
}