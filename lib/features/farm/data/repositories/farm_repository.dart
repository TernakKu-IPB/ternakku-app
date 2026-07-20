import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/repositories/base_repository.dart';

final farmRepositoryProvider = Provider((ref) {
  return FarmRepository(ref.read(dioProvider));
});

class FarmRepository extends BaseRepository {
  final Dio _dio;

  FarmRepository(this._dio);

  // Mengambil data peternakan milik user yang sedang login
  Future<Map<String, dynamic>> getMyFarm() async {
    return request(() async {
      final response = await _dio.get(ApiConstants.getMyFarm);
      return response.data;
    });
  }

  // Membuat atau memperbarui data peternakan
  Future<Map<String, dynamic>> createOrUpdateMyFarm({
    required String name,
    required String address,
    required double? latitude,
    required double? longitude,
    required String? description,
  }) async {
    return request(() async {
      final response = await _dio.patch(
        ApiConstants.updateMyFarm,
        data: {
          "name": name,
          "address": address,
          "latitude": ?latitude,
          "longitude": ?longitude,
          "description": ?description,
        },
      );
      return response.data;
    });
  }

  Future<List<Map<String, dynamic>>> getAnimalTypes({
    int limit = 10,
    int offset = 0,
    String? query,
  }) async {
    final response = await _dio.get(
        ApiConstants.animalType,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );

    return List<Map<String, dynamic>>.from(response.data['data']['animalTypes']);
  }

  Future<Map<String, dynamic>> getAnimalTypeDetail(int id) async {
    final response = await _dio.get('${ApiConstants.animalType}/$id');
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getConditionTypes({
    int limit = 20,
    int offset = 0,
    String? query,
  }) async {
    final response = await _dio.get(
      ApiConstants.conditionType,
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return List<Map<String, dynamic>>.from(
        response.data['data']['conditionTypes']);
  }

  Future<Map<String, dynamic>> getConditionTypeDetail(int id) async {
    final response = await _dio.get('${ApiConstants.conditionType}/$id');
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getVaccines({
    int limit = 20,
    int offset = 0,
    String? query,
  }) async {
    final response = await _dio.get(
      ApiConstants.vaccine,
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return List<Map<String, dynamic>>.from(
        response.data['data']['vaccines']);
  }

  Future<Map<String, dynamic>> getVaccineDetail(int id) async {
    final response = await _dio.get('${ApiConstants.vaccine}/$id');
    return response.data['data'];
  }
}
