import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/token_service.dart';
import '../../data/repositories/auth_repository.dart';

final authControllerProvider = Provider((ref) {
  return AuthController(
    ref,
    ref.read(authRepositoryProvider),
    ref.read(tokenServiceProvider),
  );
});

class AuthController {
  final Ref ref;
  final AuthRepository _repository;
  final TokenService _tokenService;

  AuthController(this.ref, this._repository, this._tokenService);

  Future<String> login(String identifier, String password) async {
    // Memanggil repository
    final response = await _repository.login(identifier, password);
    
    // Mengekstrak data token dari respons JSON (200)
    final data = response['data'];
    
    // Menyimpan token ke penyimpanan aman
    await _tokenService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    // Muat ulang auth state
    ref.invalidate(authProvider);
    
    return response['message'];
  }

  Future<String> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _repository.register(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    
    // Simpan token langsung sesuai API (isVerified: false)
    final data = response['data'];
    await _tokenService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    // Muat ulang auth state
    ref.invalidate(authProvider);

    // Mengembalikan pesan sukses dari API agar bisa ditampilkan di UI
    return response['message'];
  }

  Future <String> logout() async {
    final response = await _repository.logout();
    await _tokenService.clearTokens();
    ref.invalidate(authProvider);
    return response['message'];
  }

  Future<String> verifyEmail(String otpCode) async {
    final response = await _repository.verifyEmail(otpCode);
    
    // Perbarui state lokal secara instan tanpa perlu hit /user/me lagi
    ref.read(authProvider.notifier).markAsVerified();
    
    return response['message'];
  }

  Future<String> resendVerification() async {
    final response = await _repository.resendVerification();
    return response['message'];
  }

  Future<String> forgotPassword(String identifier) async {
    final response = await _repository.forgotPassword(identifier);
    return response['message'];
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _repository.resetPassword(
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    
    final data = response['data'];
    await _tokenService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    ref.invalidate(authProvider);
    
    return response['message'];
  }
}