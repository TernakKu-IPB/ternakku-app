import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/core/constants/api_constants.dart';
import 'package:ternakku_app/core/network/dio_client.dart';
import 'package:ternakku_app/core/repositories/base_repository.dart';
import '../../domain/models/vaccination_history_model.dart';

final vaccinationHistoryRepositoryProvider =
    Provider<VaccinationHistoryRepository>((ref) {
  return VaccinationHistoryRepository(ref.read(dioProvider));
});

class VaccinationHistoryRepository extends BaseRepository {
  final Dio _dio;

  VaccinationHistoryRepository(this._dio);

  // 1. Ambil daftar rekam medis (dengan Search & Filter & Pagination)
  //    GET /vaccination-histories → ada relasi livestock & vaccine
  Future<List<VaccinationHistoryModel>> getVaccinationHistories({
    int limit = 10,
    int offset = 0,
    String? query,
    int? livestockId,
    int? vaccineId,
    bool? isVaccinated,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return request(() async {
      final response = await _dio.get(
        ApiConstants.vaccinationHistory,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (query != null && query.isNotEmpty) 'q': query,
          if (livestockId != null && !livestockId.isNegative)
            'livestockId': livestockId,
          if (vaccineId != null && vaccineId > 0) 'vaccineId': vaccineId,
          if (isVaccinated != null) 'isVaccinated': isVaccinated,
          if (startDate != null)
            'startDate': startDate.toIso8601String().split('T').first,
          if (endDate != null)
            'endDate': endDate.toIso8601String().split('T').first,
        },
      );

      final List data =
          response.data['data']['vaccinationHistories'];
      return data
          .map((json) => VaccinationHistoryModel.fromJson(json))
          .toList();
    });
  }

  // 2. Ambil detail satu rekam medis
  Future<VaccinationHistoryModel> getVaccinationHistoryDetail(int id) async {
    return request(() async {
      final response =
          await _dio.get('${ApiConstants.vaccinationHistory}/$id');
      return VaccinationHistoryModel.fromJson(response.data['data']);
    });
  }

  // 3. Tambah rekam medis baru
  Future<VaccinationHistoryModel> createVaccinationHistory(
      Map<String, dynamic> data) async {
    return request(() async {
      final response = await _dio.post(
        ApiConstants.vaccinationHistory,
        data: data,
      );
      return VaccinationHistoryModel.fromJson(response.data['data']);
    });
  }

  // 4. Update rekam medis
  Future<VaccinationHistoryModel> updateVaccinationHistory(
      int id, Map<String, dynamic> data) async {
    return request(() async {
      final response = await _dio.patch(
        '${ApiConstants.vaccinationHistory}/$id',
        data: data,
      );
      return VaccinationHistoryModel.fromJson(response.data['data']);
    });
  }

  // 5. Hapus rekam medis
  Future<int> deleteVaccinationHistory(int id) async {
    return request(() async {
      final response =
          await _dio.delete('${ApiConstants.vaccinationHistory}/$id');
      return response.data['data']['id'] ?? id;
    });
  }

  // 6. Mark as vaccinated (PATCH isVaccinated=true) – aksi cepat dari list
  Future<VaccinationHistoryModel> markAsVaccinated(int id) async {
    return request(() async {
      final response = await _dio.patch(
        '${ApiConstants.vaccinationHistory}/$id',
        data: {'isVaccinated': true},
      );
      return VaccinationHistoryModel.fromJson(response.data['data']);
    });
  }
}
