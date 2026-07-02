import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/features/auth/data/repositories/user_repository.dart';
import 'package:ternakku_app/features/auth/domain/models/user_model.dart';
import '../../../../core/services/token_service.dart';

final userControllerProvider = Provider((ref) {
  return UserController(
    ref,
    ref.read(userRepositoryProvider),
    ref.read(tokenServiceProvider),
  );
});

class UserController {
  final Ref ref;
  final UserRepository _repository;
  final TokenService _tokenService;

  UserController(this.ref, this._repository, this._tokenService);

  Future<UserModel?> checkAndGetUser() async {
    final token = await _tokenService.getAccessToken();
    
    if (token == null) {
      return null;
    }

    try {
      return await _repository.getProfile();
    } catch (e) {
      // Jika profil gagal diambil (misal token benar-benar mati dan gagal di-refresh)
      await _tokenService.clearTokens();
      return null;
    }
  }
}