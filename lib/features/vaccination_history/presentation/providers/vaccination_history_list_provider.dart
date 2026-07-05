import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/vaccination_history_model.dart';
import '../../data/repositories/vaccination_history_repository.dart';

// 1. Class untuk menampung seluruh state halaman List
class VaccinationHistoryListState {
  final List<VaccinationHistoryModel> histories;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final int offset;
  final String query;
  final int? livestockId;
  final int? vaccineId;
  final bool? isVaccinatedFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  VaccinationHistoryListState({
    this.histories = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.query = '',
    this.livestockId,
    this.vaccineId,
    this.isVaccinatedFilter,
    this.startDate,
    this.endDate,
  });

  VaccinationHistoryListState copyWith({
    List<VaccinationHistoryModel>? histories,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    int? offset,
    String? query,
    Object? livestockId = _sentinel,
    Object? vaccineId = _sentinel,
    Object? isVaccinatedFilter = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
  }) {
    return VaccinationHistoryListState(
      histories: histories ?? this.histories,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      query: query ?? this.query,
      livestockId:
          livestockId == _sentinel ? this.livestockId : (livestockId as int?),
      vaccineId:
          vaccineId == _sentinel ? this.vaccineId : (vaccineId as int?),
      isVaccinatedFilter: isVaccinatedFilter == _sentinel
          ? this.isVaccinatedFilter
          : (isVaccinatedFilter as bool?),
      startDate:
          startDate == _sentinel ? this.startDate : (startDate as DateTime?),
      endDate: endDate == _sentinel ? this.endDate : (endDate as DateTime?),
    );
  }
}

// Sentinel object untuk membedakan "tidak dilewatkan" vs "dilewatkan null"
const _sentinel = Object();

// 2. Provider
final vaccinationHistoryListProvider = StateNotifierProvider<
    VaccinationHistoryListNotifier, VaccinationHistoryListState>((ref) {
  return VaccinationHistoryListNotifier(
      ref.read(vaccinationHistoryRepositoryProvider));
});

// 3. Notifier
class VaccinationHistoryListNotifier
    extends StateNotifier<VaccinationHistoryListState> {
  final VaccinationHistoryRepository _repository;
  final int _limit = 10;

  VaccinationHistoryListNotifier(this._repository)
      : super(VaccinationHistoryListState()) {
    fetchHistories(); // Ambil data pertama kali saat provider diinisialisasi
  }

  Future<void> fetchHistories({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isLoading: true, offset: 0, hasMore: true);
    } else {
      if (!state.hasMore || state.isLoadMore || state.isLoading) return;
      state = state.copyWith(isLoadMore: true);
    }

    try {
      final newItems = await _repository.getVaccinationHistories(
        limit: _limit,
        offset: isRefresh ? 0 : state.offset,
        query: state.query,
        livestockId: state.livestockId,
        vaccineId: state.vaccineId,
        isVaccinated: state.isVaccinatedFilter,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      state = state.copyWith(
        histories: isRefresh ? newItems : [...state.histories, ...newItems],
        offset: (isRefresh ? 0 : state.offset) + newItems.length,
        hasMore: newItems.length == _limit,
        isLoading: false,
        isLoadMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadMore: false);
    }
  }

  // Aksi cepat: tandai sudah divaksinasi langsung dari list
  Future<void> markAsVaccinated(int id) async {
    try {
      final updated = await _repository.markAsVaccinated(id);
      // Update item di list secara lokal tanpa harus re-fetch
      state = state.copyWith(
        histories: state.histories.map((h) {
          return h.id == id ? updated : h;
        }).toList(),
      );
    } catch (_) {
      rethrow;
    }
  }

  // --- Fungsi Filter & Search ---

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    fetchHistories(isRefresh: true);
  }

  void updateLivestockFilter(int? livestockId) {
    state = state.copyWith(livestockId: livestockId);
    fetchHistories(isRefresh: true);
  }

  void updateVaccineFilter(int? vaccineId) {
    state = state.copyWith(vaccineId: vaccineId);
    fetchHistories(isRefresh: true);
  }

  void updateIsVaccinatedFilter(bool? isVaccinated) {
    state = state.copyWith(isVaccinatedFilter: isVaccinated);
    fetchHistories(isRefresh: true);
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
    fetchHistories(isRefresh: true);
  }

  void clearFilters() {
    state = VaccinationHistoryListState(query: state.query);
    fetchHistories(isRefresh: true);
  }
}
