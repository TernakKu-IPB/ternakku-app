
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';

final animalTemplatesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(farmRepositoryProvider).getAnimalTypeTemplates();
});

final conditionTemplatesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(farmRepositoryProvider).getConditionTypeTemplates();
});

final vaccineTemplatesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(farmRepositoryProvider).getVaccineTemplates();
});