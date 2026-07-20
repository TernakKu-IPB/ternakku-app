import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/condition_history_model.dart';
import '../../data/repositories/condition_history_repository.dart';

// 1. Class untuk menampung seluruh state halaman List
class ConditionHistoryListState {
  final List<ConditionHistoryModel> histories;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final int offset;
  final String query;
  final int? livestockId;
  final int? conditionTypeId;
  final DateTime? startDate;
  final DateTime? endDate;

  ConditionHistoryListState({
    this.histories = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.query = '',
    this.livestockId,
    this.conditionTypeId,
    this.startDate,
    this.endDate,
  });

  ConditionHistoryListState copyWith({
    List<ConditionHistoryModel>? histories,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    int? offset,
    String? query,
    Object? livestockId = _sentinel,
    Object? conditionTypeId = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
  }) {
    return ConditionHistoryListState(
      histories: histories ?? this.histories,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      query: query ?? this.query,
      livestockId: livestockId == _sentinel ? this.livestockId : (livestockId as int?),
      conditionTypeId: conditionTypeId == _sentinel ? this.conditionTypeId : (conditionTypeId as int?),
      startDate: startDate == _sentinel ? this.startDate : (startDate as DateTime?),
      endDate: endDate == _sentinel ? this.endDate : (endDate as DateTime?),
    );
  }
}

// Sentinel object untuk membedakan "tidak dilewatkan" vs "dilewatkan null"
const _sentinel = Object();

// 2. Provider
final conditionHistoryListProvider =
    StateNotifierProvider<ConditionHistoryListNotifier, ConditionHistoryListState>((ref) {
  return ConditionHistoryListNotifier(ref.read(conditionHistoryRepositoryProvider));
});

// 3. Notifier
class ConditionHistoryListNotifier extends StateNotifier<ConditionHistoryListState> {
  final ConditionHistoryRepository _repository;
  final int _limit = 10;

  ConditionHistoryListNotifier(this._repository) : super(ConditionHistoryListState()) {
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
      final newItems = await _repository.getConditionHistories(
        limit: _limit,
        offset: isRefresh ? 0 : state.offset,
        query: state.query,
        livestockId: state.livestockId,
        conditionTypeId: state.conditionTypeId,
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

  // --- Fungsi Filter & Search ---

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    fetchHistories(isRefresh: true);
  }

  void updateLivestockFilter(int? livestockId) {
    state = state.copyWith(livestockId: livestockId);
    fetchHistories(isRefresh: true);
  }

  void updateConditionTypeFilter(int? conditionTypeId) {
    state = state.copyWith(conditionTypeId: conditionTypeId);
    fetchHistories(isRefresh: true);
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
    fetchHistories(isRefresh: true);
  }

  void clearFilters({ bool isFilteredMode = false }) {
    // Pertahankan livestockId yang sudah ada (misalnya saat dibuka dari detail ternak)
    state = ConditionHistoryListState(
      query: state.query,
      livestockId: isFilteredMode ? state.livestockId : null,
    );
    fetchHistories(isRefresh: true);
  }
}
