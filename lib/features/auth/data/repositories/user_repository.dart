import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/features/auth/data/repositories/base_repository.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/user_model.dart';

final userRepositoryProvider = Provider((ref) {
  return UserRepository(ref.read(dioProvider));
});

class UserRepository extends BaseRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<UserModel> getProfile() async {
    return request(() async {
      final response = await _dio.get(ApiConstants.getProfile);
      return UserModel.fromJson(response.data['data']);
    });
  }
}