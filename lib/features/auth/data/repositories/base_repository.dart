import 'package:dio/dio.dart';
import 'package:ternakku_app/core/network/api_exception.dart';

abstract class BaseRepository {
  Future<T> request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  ApiException parseDioError(DioException e) {
    if (e.response == null || e.response?.data == null) {
      return const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        statusCode: 500,
      );
    }

    final errorData = e.response!.data;

    final statusCode =
        errorData['statusCode'] ??
        e.response!.statusCode ??
        500;

    final message =
        errorData['message'] ??
        'Terjadi kesalahan pada server';

    final fieldErrors = <String, String>{};

    if (statusCode == 400 && errorData['error'] is List) {
      for (final err in errorData['error']) {
        if (err['path'] is List && err['path'].isNotEmpty) {
          fieldErrors[err['path'][0].toString()] =
              err['message']?.toString() ??
                  'Input tidak valid';
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