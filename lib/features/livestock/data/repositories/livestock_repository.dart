import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/core/constants/api_constants.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/network/dio_client.dart';
import 'package:ternakku_app/core/repositories/base_repository.dart';
import '../../domain/models/livestock_model.dart';

final livestockRepositoryProvider = Provider<LivestockRepository>((ref) {
  return LivestockRepository(ref.read(dioProvider));
});

class LivestockRepository extends BaseRepository {
  final Dio _dio;

  LivestockRepository(this._dio);

  // 1. Ambil daftar ternak (beserta Search & Filter)
  Future<List<LivestockModel>> getLivestocks({
    int limit = 10,
    int offset = 0,
    String? query,
    String? status,
    String? gender,
    int? animalTypeId,
  }) async {
    return request(() async {
      final response = await _dio.get(
        ApiConstants.livestock,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (query != null && query.isNotEmpty) 'q': query,
          if (status != null && status != 'all') 'status': status,
          if (gender != null && gender != 'all') 'gender': gender,
          if (animalTypeId != null && !animalTypeId.isNegative) 'animalTypeId': animalTypeId,
        },
      );

      final List data = response.data['data']['livestocks'];
      return data.map((json) => LivestockModel.fromJson(json)).toList();
    });
  }

  // 2. Ambil detail satu ternak
  Future<LivestockModel> getLivestockDetail(int id) async {
    return request(() async {
      final endpoint = ApiConstants.livestock;
      final response = await _dio.get('$endpoint/$id');
      return LivestockModel.fromJson(response.data['data']);
    });
  }

  // 3. Tambah ternak baru
  Future<LivestockModel> createLivestock(Map<String, dynamic> data) async {
    try {
      return request(() async {
        final response = await _dio.post(
          ApiConstants.livestock,
          data: data,
        );
        return LivestockModel.fromJson(response.data['data']);
      });
    } on ApiException catch (error) {
      if (
        error.statusCode == 404 || 
        error.statusCode == 422
      ) {
        if (error.message.toLowerCase().contains('induk')) {
          throw error.copyWith(
            fieldErrors: {
              'motherId': error.message,
            },
          );
        } else if (error.message.toLowerCase().contains('pejantan')) {
          throw error.copyWith(
            fieldErrors: {
              'fatherId': error.message,
            },
          );
        }
      }
      rethrow;
    }
  }

  // 4. Update data ternak
  Future<LivestockModel> updateLivestock(int id, Map<String, dynamic> data) async {
    try {
      return request(() async {
        final endpoint = ApiConstants.livestock;
        final response = await _dio.patch(
          '$endpoint/$id',
          data: data,
        );
        return LivestockModel.fromJson(response.data['data']);
      });
    } on ApiException catch (error) {
      if (
        error.statusCode == 404 || 
        error.statusCode == 422
      ) {
        if (error.message.toLowerCase().contains('induk/pejantan')) {
          throw error.copyWith(
            fieldErrors: {
              'fatherId': error.message,
              'motherId': error.message,
            }
          );
        } else if (error.message.toLowerCase().contains('induk')) {
          throw error.copyWith(
            fieldErrors: {
              'motherId': error.message,
            },
          );
        } else if (error.message.toLowerCase().contains('pejantan') ) {
          throw error.copyWith(
            fieldErrors: {
              'fatherId': error.message,
            },
          );
        } else if (error.message.toLowerCase().contains('jenis kelamin menjadi')) {
          throw error.copyWith(
            fieldErrors: {
              'gender': error.message,
            }
          );
        }
      }
      rethrow;
    }
  }

  // 5. Hapus ternak
  Future<int> deleteLivestock(int id) async {
    return request(() async {
      final endpoint = ApiConstants.livestock;
      final response = await _dio.delete('$endpoint/$id');
      return response.data['data']['id'] ?? id; 
    });
  }
}