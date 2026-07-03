import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ternakku_app/features/auth/presentation/providers/user_controller.dart';
import '../../domain/models/user_model.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Mendelegasikan logika pengambilan profil dan cek token ke AuthController
    return await ref.read(userControllerProvider).checkAndGetUser();
  }

  // Fungsi helper saat OTP sukses (supaya tidak perlu hit API getProfile ulang)
  void markAsVerified() {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(isVerified: true));
    }
  }

  // Fungsi helper saat Onboarding sukses
  void markAsHasFarm() {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(hasFarm: true));
    }
  }
}