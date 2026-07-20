import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/farm_repository.dart';

final farmInfoDetailsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(farmRepositoryProvider);
  final response = await repo.getMyFarm();
  return response['data'] as Map<String, dynamic>;
});
