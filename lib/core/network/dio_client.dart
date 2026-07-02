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
        if (e.response?.statusCode == 401) {
          final refreshToken = await tokenService.getRefreshToken();
          
          if (refreshToken != null) {
            try {
              // Coba perbarui token
              final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
              final response = await refreshDio.post(
                ApiConstants.refresh,
                data: {'refreshToken': refreshToken},
              );
              
              // Simpan token baru
              final newAccessToken = response.data['data']['accessToken'];
              final newRefreshToken = response.data['data']['refreshToken'];
              await tokenService.saveTokens(
                accessToken: newAccessToken, 
                refreshToken: newRefreshToken,
              );
              
              // Ulangi request yang gagal tadi dengan token baru
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
              
            } catch (refreshError) {
              // 1. Hapus token lokal karena sudah benar-benar kedaluwarsa
              await tokenService.clearTokens();
              
              // 2. Reload state user
              ref.invalidate(authProvider);
              
              return handler.reject(e); // Reject request asli
            }
          }
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});