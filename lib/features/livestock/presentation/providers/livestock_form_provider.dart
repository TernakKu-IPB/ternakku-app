import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';

final farmAnimalTypesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(farmRepositoryProvider).getAnimalTypes();
});