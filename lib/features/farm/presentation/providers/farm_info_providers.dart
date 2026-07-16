import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/farm_repository.dart';

final farmInfoDetailsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(farmRepositoryProvider);
  final response = await repo.getMyFarm();
  return response['data'] as Map<String, dynamic>;
});

final farmInfoAnimalTypesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(farmRepositoryProvider);
  return await repo.getAnimalTypes(limit: 100);
});

final farmInfoConditionTypesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(farmRepositoryProvider);
  return await repo.getConditionTypes(limit: 100);
});

final farmInfoVaccinesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(farmRepositoryProvider);
  return await repo.getVaccines(limit: 100);
});
