import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenService = ref.read(tokenServiceProvider);
  
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Menambahkan Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      // 1. Sebelum request dikirim, sisipkan token jika ada
      onRequest: (options, handler) async {
        final accessToken = await tokenService.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      
      // 2. Jika terjadi error (khususnya 401 Unauthorized / Token Expired)
      onError: (DioException e, handler) async {
        if (e.response?.statusCode != 401) {
          return handler.next(e);
        }

        final refreshToken = await tokenService.getRefreshToken();
        if (refreshToken == null) {
          await tokenService.clearTokens();
          ref.invalidate(authProvider);
          return handler.next(e);
        }

        try {
          // Refresh access token
          final refreshDio = Dio(
            BaseOptions(baseUrl: ApiConstants.baseUrl),
          );

          final response = await refreshDio.post(
            ApiConstants.refresh,
            data: {
              'refreshToken': refreshToken,
            },
          );

          final newAccessToken = response.data['data']['accessToken'];
          final newRefreshToken = response.data['data']['refreshToken'];

          await tokenService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry request
          final requestOptions = e.requestOptions;
          requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';

          try {
            final retryResponse = await dio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            // 409, 422, 400, dll.
            return handler.reject(retryError);
          }
        } on DioException {
          // Refresh token memang gagal
          await tokenService.clearTokens();
          ref.invalidate(authProvider);

          return handler.next(e);
        }
      },
    ),
  );

  return dio;
});