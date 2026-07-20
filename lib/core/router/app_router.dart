// import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ternakku_app/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:ternakku_app/features/condition_history/domain/models/condition_history_model.dart';
import 'package:ternakku_app/features/condition_history/presentation/screens/condition_history_detail_screen.dart';
import 'package:ternakku_app/features/condition_history/presentation/screens/condition_history_form_screen.dart';
import 'package:ternakku_app/features/condition_history/presentation/screens/condition_history_list_screen.dart';
import 'package:ternakku_app/features/livestock/domain/models/livestock_model.dart';
import 'package:ternakku_app/features/livestock/presentation/screens/livestock_detail_screen.dart';
import 'package:ternakku_app/features/livestock/presentation/screens/livestock_form_screen.dart';
import 'package:ternakku_app/features/livestock/presentation/screens/livestock_list_screen.dart';
import 'package:ternakku_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ternakku_app/features/vaccination_history/domain/models/vaccination_history_model.dart';
import 'package:ternakku_app/features/vaccination_history/presentation/screens/vaccination_history_detail_screen.dart';
import 'package:ternakku_app/features/vaccination_history/presentation/screens/vaccination_history_form_screen.dart';
import 'package:ternakku_app/features/vaccination_history/presentation/screens/vaccination_history_list_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import 'package:ternakku_app/features/farm/presentation/screens/farm_info_screen.dart';

final goRouter = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',

    redirect: (context, state) {
      if (authState.isLoading) return null;

      final user = authState.value;
      final isLogin = state.matchedLocation == '/login';
      final isRegister = state.matchedLocation == '/register';
      final isVerify = state.matchedLocation == '/verify-email';
      final isForgot = state.matchedLocation == '/forgot-password';
      final isReset = state.matchedLocation == '/reset-password';

      // Skenario 1: Belum Login (user == null)
      if (user == null) {
        final isAuthPath = isLogin || isRegister || isForgot || isReset;
                           
        if (!isAuthPath) {
          return '/login';
        }
        return null;
      }

      // Skenario 2: Sudah Login, tapi Belum Verifikasi Email
      if (!user.isVerified) {
        if (!isVerify) {
          return '/verify-email'; // Kunci di halaman verifikasi
        }
        return null;
      }

      final isOnboarding = state.matchedLocation == '/on-boarding';

      // Skenario 3: Sudah Terverifikasi, tapi Belum Punya Peternakan
      if (user.isVerified && !user.hasFarm) {
        if (!isOnboarding) {
          return '/on-boarding';
        }
        return null;
      }

      // Skenario 4: Sudah Punya Peternakan (Selesai Onboarding)
      if (isLogin || isRegister || isVerify || isOnboarding) {
        return '/dashboard'; 
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          // Menangkap nilai ?token=xxx dari Deep Link
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/on-boarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/livestock', builder: (context, state) => const LivestockListScreen()),
      GoRoute(
        path: '/livestock/form',
        builder: (context, state) {
          // Tangkap extra object untuk mode edit
          final livestockToEdit = state.extra as LivestockModel?;
          return LivestockFormScreen(livestock: livestockToEdit);
        },
      ),
      GoRoute(
        path: '/livestock/detail',
        builder: (context, state) {
          final livestock = state.extra as LivestockModel;
          return LivestockDetailScreen(livestock: livestock);
        },
      ),

      // ---- Catatan Harian (Condition History) ----
      GoRoute(
        path: '/condition-history',
        builder: (context, state) {
          // Bisa dibuka tanpa extra (dari nav bottom), atau dengan extra map berisi
          // {livestockId: int, livestockName: String} saat dibuka dari livestock detail
          final extra = state.extra as Map<String, dynamic>?;
          return ConditionHistoryListScreen(
            livestockId: extra?['livestockId'] as int?,
            livestockName: extra?['livestockName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/condition-history/form',
        builder: (context, state) {
          final historyToEdit = state.extra as ConditionHistoryModel?;
          final livestockId = int.tryParse(
            state.uri.queryParameters['livestockId'] ?? '',
          );
          return ConditionHistoryFormScreen(history: historyToEdit, livestockId: livestockId);
        },
      ),
      GoRoute(
        path: '/condition-history/detail',
        builder: (context, state) {
          final history = state.extra as ConditionHistoryModel;
          return ConditionHistoryDetailScreen(history: history);
        },
      ),

      // ---- Rekam Medis (Vaccination History) ----
      GoRoute(
        path: '/vaccination-history',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VaccinationHistoryListScreen(
            livestockId: extra?['livestockId'] as int?,
            livestockName: extra?['livestockName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/vaccination-history/form',
        builder: (context, state) {
          final historyToEdit = state.extra as VaccinationHistoryModel?;
          final livestockId = int.tryParse(
            state.uri.queryParameters['livestockId'] ?? '',
          );
          return VaccinationHistoryFormScreen(history: historyToEdit, livestockId: livestockId);
        },
      ),
      GoRoute(
        path: '/vaccination-history/detail',
        builder: (context, state) {
          final history = state.extra as VaccinationHistoryModel;
          return VaccinationHistoryDetailScreen(history: history);
        },
      ),
      GoRoute(
        path: '/farm-info',
        builder: (context, state) => const FarmInfoScreen(),
      ),
    ],
  );
});