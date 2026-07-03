import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/features/auth/data/repositories/user_repository.dart';
import 'package:ternakku_app/features/auth/domain/models/user_model.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import '../../../../core/services/token_service.dart';

final userControllerProvider = Provider((ref) {
  return UserController(
    ref,
    ref.read(userRepositoryProvider),
    ref.read(tokenServiceProvider),
    ref.read(farmRepositoryProvider),
  );
});

class UserController {
  final Ref ref;
  final UserRepository _userRepository;
  final TokenService _tokenService;
  final FarmRepository _farmRepository;

  UserController(this.ref, this._userRepository, this._tokenService, this._farmRepository);

  Future<UserModel?> checkAndGetUser() async {
    final token = await _tokenService.getAccessToken();
    
    if (token == null) {
      return null;
    }

    try {
      UserModel userModel = await _userRepository.getProfile();
      
      bool hasFarm = false;
      try {
        final farmResponse = await _farmRepository.getMyFarm();
        if (farmResponse['data'] != null) {
          hasFarm = true;
        }
      } catch (e) {
        hasFarm = false; 
      }

      return UserModel(
        id: userModel.id, 
        username: userModel.username, 
        email: userModel.email, 
        fullName: userModel.fullName, 
        isVerified: userModel.isVerified, 
        hasFarm: hasFarm
      );
    } catch (e) {
      return null;
    }
  }
}