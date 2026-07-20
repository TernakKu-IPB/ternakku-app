import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../farm/data/repositories/farm_repository.dart';

final onboardingControllerProvider = Provider((ref) {
  return OnboardingController(ref.read(farmRepositoryProvider));
});

class OnboardingController {
  final FarmRepository _repository;

  OnboardingController(this._repository);

  Future<void> submitOnboarding({
    required String name,
    required String address,
    String? description,
    String? latitude,
    String? longitude,
  }) async {
    // 1. Simpan Profil Peternakan terlebih dahulu
    await _repository.createOrUpdateMyFarm(
      name: name,
      address: address,
      description: description,
      latitude: latitude != null ? double.tryParse(latitude) : null,
      longitude: longitude != null ? double.tryParse(longitude) : null,
    );
  }
}