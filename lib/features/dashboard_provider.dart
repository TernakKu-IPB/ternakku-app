import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import 'package:ternakku_app/features/livestock/data/repositories/livestock_repository.dart';
import 'package:ternakku_app/features/condition_history/data/repositories/condition_history_repository.dart';
import 'package:ternakku_app/features/vaccination_history/data/repositories/vaccination_history_repository.dart';

class DashboardActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final String statusText;
  final Color statusColor;
  final IconData icon;
  final DateTime date;

  DashboardActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.statusText,
    required this.statusColor,
    required this.icon,
    required this.date,
  });
}

class DashboardState {
  final String farmName;
  final int totalTernak;
  final int perluPerhatian;
  final int vaksinTerjadwal;
  final List<DashboardActivityItem> recentActivities;
  final bool isLoading;
  final bool isError;

  DashboardState({
    this.farmName = 'Peternakan Anda',
    this.totalTernak = 0,
    this.perluPerhatian = 0,
    this.vaksinTerjadwal = 0,
    this.recentActivities = const [],
    this.isLoading = false,
    this.isError = false,
  });

  DashboardState copyWith({
    String? farmName,
    int? totalTernak,
    int? perluPerhatian,
    int? vaksinTerjadwal,
    List<DashboardActivityItem>? recentActivities,
    bool? isLoading,
    bool? isError,
  }) {
    return DashboardState(
      farmName: farmName ?? this.farmName,
      totalTernak: totalTernak ?? this.totalTernak,
      perluPerhatian: perluPerhatian ?? this.perluPerhatian,
      vaksinTerjadwal: vaksinTerjadwal ?? this.vaksinTerjadwal,
      recentActivities: recentActivities ?? this.recentActivities,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    ref.read(farmRepositoryProvider),
    ref.read(livestockRepositoryProvider),
    ref.read(conditionHistoryRepositoryProvider),
    ref.read(vaccinationHistoryRepositoryProvider),
  );
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final FarmRepository _farmRepo;
  final LivestockRepository _livestockRepo;
  final ConditionHistoryRepository _conditionRepo;
  final VaccinationHistoryRepository _vaccinationRepo;

  DashboardNotifier(
    this._farmRepo,
    this._livestockRepo,
    this._conditionRepo,
    this._vaccinationRepo,
  ) : super(DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, isError: false);
    try {
      // Fetch all required data in parallel
      final results = await Future.wait([
        _farmRepo.getMyFarm(),
        _livestockRepo.getLivestocks(limit: 1000, status: 'active'),
        _conditionRepo.getConditionHistories(limit: 100),
        _vaccinationRepo.getVaccinationHistories(limit: 100),
      ]);

      final farmData = results[0] as Map<String, dynamic>;
      final livestocks = results[1] as List;
      final conditionHistories = results[2] as List;
      final vaccinationHistories = results[3] as List;

      // 1. Farm Name
      final farmName = farmData['data']?['name'] as String? ?? 'Peternakan Anda';

      // 2. Total active livestock
      final totalTernak = livestocks.length;

      // 3. Perlu Perhatian (active livestock whose latest condition is sick)
      int perluPerhatian = 0;
      final Map<int, DateTime> latestConditionDates = {};
      final Map<int, String> latestConditionLabels = {};

      for (final history in conditionHistories) {
        final lsId = history.livestockId;
        final date = history.recordDate;
        final label = history.conditionType?['label'] as String? ?? '';

        if (!latestConditionDates.containsKey(lsId) ||
            date.isAfter(latestConditionDates[lsId]!)) {
          latestConditionDates[lsId] = date;
          latestConditionLabels[lsId] = label;
        }
      }

      for (final livestock in livestocks) {
        final label = latestConditionLabels[livestock.id];
        if (label != null) {
          final lower = label.toLowerCase();
          if (lower.contains('sakit') ||
              lower.contains('ill') ||
              lower.contains('sick')) {
            perluPerhatian++;
          }
        }
      }

      // 4. Vaksin Terjadwal (unvaccinated histories)
      int vaksinTerjadwal = 0;
      for (final history in vaccinationHistories) {
        if (!history.isVaccinated) {
          vaksinTerjadwal++;
        }
      }

      // 5. Recent Activities (mix of recent condition records and vaccination logs)
      final List<DashboardActivityItem> activities = [];

      // Add condition logs
      for (final history in conditionHistories.take(5)) {
        final condLabel = history.conditionType?['label'] as String? ?? 'Kondisi';
        final lsName = history.livestock?['name'] as String? ?? 'Ternak';
        final lsTag = history.livestock?['tagId'] as String?;

        activities.add(DashboardActivityItem(
          title: 'Pencatatan Kondisi $condLabel',
          subtitle: '$lsName${lsTag != null ? ' • Tag #$lsTag' : ''}',
          time: _getRelativeTime(history.createdAt),
          statusText: condLabel,
          statusColor: _getConditionColor(condLabel),
          icon: _getConditionIcon(condLabel),
          date: history.createdAt,
        ));
      }

      // Add vaccination logs
      for (final history in vaccinationHistories.take(5)) {
        final vaccineName = history.vaccine?['name'] as String? ?? 'Vaksin';
        final lsName = history.livestock?['name'] as String? ?? 'Ternak';
        final lsTag = history.livestock?['tagId'] as String?;

        final isOverdue = !history.isVaccinated &&
            history.vaccinationDate.isBefore(DateTime.now());
        final diff = history.vaccinationDate.difference(DateTime.now()).inDays;
        final isUpcoming = !history.isVaccinated && diff >= 0 && diff <= 7;

        final statusText = history.isVaccinated
            ? 'Selesai'
            : isOverdue
                ? 'Terlambat'
                : isUpcoming
                    ? 'Segera'
                    : 'Terjadwal';

        final statusColor = history.isVaccinated
            ? const Color(0xFF22C55E)
            : isOverdue
                ? const Color(0xFFEF4444)
                : isUpcoming
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF3B82F6);

        activities.add(DashboardActivityItem(
          title: 'Suntik Vaksin $vaccineName',
          subtitle: '$lsName${lsTag != null ? ' • Tag #$lsTag' : ''}',
          time: _getRelativeTime(history.createdAt),
          statusText: statusText,
          statusColor: statusColor,
          icon: Icons.vaccines_rounded,
          date: history.createdAt,
        ));
      }

      // Sort activities descending by date
      activities.sort((a, b) => b.date.compareTo(a.date));

      state = DashboardState(
        farmName: farmName,
        totalTernak: totalTernak,
        perluPerhatian: perluPerhatian,
        vaksinTerjadwal: vaksinTerjadwal,
        recentActivities: activities.take(5).toList(),
        isLoading: false,
        isError: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isError: true);
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (dateDay == today) {
        return 'Hari ini';
      } else if (dateDay == yesterday) {
        return 'Kemarin';
      } else {
        return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
      }
    }
  }

  Color _getConditionColor(String? conditionCode) {
    if (conditionCode == null) return const Color(0xFF3B82F6);
    final lower = conditionCode.toLowerCase();
    if (lower.contains('sehat') || lower.contains('baik') || lower.contains('normal')) {
      return const Color(0xFF22C55E); // Green
    } else if (lower.contains('sakit') || lower.contains('ill') || lower.contains('sick')) {
      return const Color(0xFFEF4444); // Red
    } else if (lower.contains('lahir') || lower.contains('birth')) {
      return const Color(0xFF3B82F6); // Blue
    } else if (lower.contains('mati') || lower.contains('dead')) {
      return const Color(0xFF6B7280); // Gray
    } else if (lower.contains('bunting') || lower.contains('hamil') || lower.contains('pregnant')) {
      return const Color(0xFFF59E0B); // Amber
    }
    return const Color(0xFF3B82F6);
  }

  IconData _getConditionIcon(String? conditionCode) {
    if (conditionCode == null) return Icons.note_alt_outlined;
    final lower = conditionCode.toLowerCase();
    if (lower.contains('sehat') || lower.contains('baik') || lower.contains('normal')) {
      return Icons.favorite_rounded;
    } else if (lower.contains('sakit') || lower.contains('ill') || lower.contains('sick')) {
      return Icons.sick_rounded;
    } else if (lower.contains('lahir') || lower.contains('birth')) {
      return Icons.child_care_rounded;
    } else if (lower.contains('mati') || lower.contains('dead')) {
      return Icons.heart_broken_rounded;
    } else if (lower.contains('bunting') || lower.contains('hamil') || lower.contains('pregnant')) {
      return Icons.pregnant_woman_rounded;
    }
    return Icons.note_alt_outlined;
  }
}
