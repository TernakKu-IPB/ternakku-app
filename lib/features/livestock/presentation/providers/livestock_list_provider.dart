import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/livestock_model.dart';
import '../../data/repositories/livestock_repository.dart';

// 1. Class untuk menampung seluruh state halaman List
class LivestockListState {
  final List<LivestockModel> livestocks;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final int offset;
  final String query;
  final String? status;
  final String? gender;
  final int? animalTypeId;

  LivestockListState({
    this.livestocks = const [],
    this.isLoading = false,
    this.isLoadMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.query = '',
    this.status,
    this.gender,
    this.animalTypeId,
  });

  LivestockListState copyWith({
    List<LivestockModel>? livestocks,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    int? offset,
    String? query,
    String? status,
    String? gender,
    int? animalTypeId,
  }) {
    return LivestockListState(
      livestocks: livestocks ?? this.livestocks,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      query: query ?? this.query,
      status: status != null ? (status == 'all' ? null : status) : this.status,
      gender: gender != null ? (gender == 'all' ? null : gender) : this.gender,
      animalTypeId: animalTypeId != null ? (animalTypeId == -1 ? null : animalTypeId) : this.animalTypeId,
    );
  }
}

// 2. Provider
final livestockListProvider = StateNotifierProvider<LivestockListNotifier, LivestockListState>((ref) {
  return LivestockListNotifier(ref.read(livestockRepositoryProvider));
});

// 3. Notifier
class LivestockListNotifier extends StateNotifier<LivestockListState> {
  final LivestockRepository _repository;
  final int _limit = 10;

  LivestockListNotifier(this._repository) : super(LivestockListState()) {
    fetchLivestocks(); // Ambil data pertama kali saat provider diinisialisasi
  }

  Future<void> fetchLivestocks({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isLoading: true, offset: 0, hasMore: true);
    } else {
      if (!state.hasMore || state.isLoadMore || state.isLoading) return;
      state = state.copyWith(isLoadMore: true);
    }

    try {
      final newItems = await _repository.getLivestocks(
        limit: _limit,
        offset: state.offset,
        query: state.query,
        status: state.status,
        gender: state.gender,
        animalTypeId: state.animalTypeId,
      );

      state = state.copyWith(
        livestocks: isRefresh ? newItems : [...state.livestocks, ...newItems],
        offset: state.offset + newItems.length,
        hasMore: newItems.length == _limit, // Jika kurang dari limit, berarti data sudah habis
        isLoading: false,
        isLoadMore: false,
      );
    } catch (e) {
      // Handle error (bisa ditambahkan properti errorMessage di State jika mau)
      state = state.copyWith(isLoading: false, isLoadMore: false);
    }
  }

  // --- Fungsi untuk Filter & Search ---

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    fetchLivestocks(isRefresh: true);
  }

  void updateStatus(String? status) {
    state = state.copyWith(status: status ?? 'all');
    fetchLivestocks(isRefresh: true);
  }

  void updateGender(String? gender) {
    state = state.copyWith(gender: gender ?? 'all');
    fetchLivestocks(isRefresh: true);
  }

  void updateAnimalType(int id) {
    state = state.copyWith(animalTypeId: id);
    fetchLivestocks(isRefresh: true);
  }
}