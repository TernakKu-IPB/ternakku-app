import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/core/constants/api_constants.dart';
import 'package:ternakku_app/core/network/dio_client.dart';
import 'package:ternakku_app/core/repositories/base_repository.dart';
import '../../domain/models/condition_history_model.dart';

final conditionHistoryRepositoryProvider = Provider<ConditionHistoryRepository>((ref) {
  return ConditionHistoryRepository(ref.read(dioProvider));
});

class ConditionHistoryRepository extends BaseRepository {
  final Dio _dio;

  ConditionHistoryRepository(this._dio);

  // 1. Ambil daftar catatan kondisi (dengan Search & Filter & Pagination)
  Future<List<ConditionHistoryModel>> getConditionHistories({
    int limit = 10,
    int offset = 0,
    String? query,
    int? livestockId,
    int? conditionTypeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return request(() async {
      final response = await _dio.get(
        ApiConstants.conditionHistory,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (query != null && query.isNotEmpty) 'q': query,
          if (livestockId != null && !livestockId.isNegative) 'livestockId': livestockId,
          if (conditionTypeId != null && conditionTypeId > 0) 'conditionTypeId': conditionTypeId,
          if (startDate != null) 'startDate': startDate.toIso8601String().split('T').first,
          if (endDate != null) 'endDate': endDate.toIso8601String().split('T').first,
        },
      );

      final List data = response.data['data']['conditionHistories'];
      return data.map((json) => ConditionHistoryModel.fromJson(json)).toList();
    });
  }

  // 2. Ambil detail satu catatan
  Future<ConditionHistoryModel> getConditionHistoryDetail(int id) async {
    return request(() async {
      final response = await _dio.get('${ApiConstants.conditionHistory}/$id');
      return ConditionHistoryModel.fromJson(response.data['data']);
    });
  }

  // 3. Tambah catatan kondisi baru
  Future<ConditionHistoryModel> createConditionHistory(Map<String, dynamic> data) async {
    return request(() async {
      final response = await _dio.post(
        ApiConstants.conditionHistory,
        data: data,
      );
      return ConditionHistoryModel.fromJson(response.data['data']);
    });
  }

  // 4. Update catatan kondisi
  Future<ConditionHistoryModel> updateConditionHistory(int id, Map<String, dynamic> data) async {
    return request(() async {
      final response = await _dio.patch(
        '${ApiConstants.conditionHistory}/$id',
        data: data,
      );
      return ConditionHistoryModel.fromJson(response.data['data']);
    });
  }

  // 5. Hapus catatan kondisi
  Future<int> deleteConditionHistory(int id) async {
    return request(() async {
      final response = await _dio.delete('${ApiConstants.conditionHistory}/$id');
      return response.data['data']['id'] ?? id;
    });
  }
}
