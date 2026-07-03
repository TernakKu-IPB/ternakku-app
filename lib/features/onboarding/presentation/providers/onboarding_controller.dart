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
    required List<Map<String, String>> allAnimalTypes,
    required List<Map<String, String>> allConditionTypes,
    required List<Map<String, String>> allVaccines,
  }) async {
    // 1. Simpan Profil Peternakan terlebih dahulu
    await _repository.createOrUpdateMyFarm(
      name: name,
      address: address,
      description: description,
      latitude: latitude != null ? double.tryParse(latitude) : null,
      longitude: longitude != null ? double.tryParse(longitude) : null,
    );

    // 2. Kumpulkan semua request master data kustom agar bisa dieksekusi bersamaan (paralel)
    List<Future> masterDataTasks = [];

    for (var type in allAnimalTypes) {
      masterDataTasks.add(_repository.addCustomAnimalType(type['code']!, type['label']!));
    }
    
    for (var condition in allConditionTypes) {
      masterDataTasks.add(_repository.addCustomConditionType(condition['code']!, condition['label']!));
    }
    
    for (var vaccine in allVaccines) {
      masterDataTasks.add(_repository.addCustomVaccine(vaccine['code']!, vaccine['label']!)); 
    }

    // 3. Eksekusi semua secara paralel untuk menghemat waktu loading
    if (masterDataTasks.isNotEmpty) {
      await Future.wait(masterDataTasks);
    }

    // Catatan: Untuk ID Template dari sistem, biasanya tidak perlu di-POST ulang
    // karena peternak cukup menggunakan ID tersebut nanti saat membuat data ternak (Livestocks).
  }
}