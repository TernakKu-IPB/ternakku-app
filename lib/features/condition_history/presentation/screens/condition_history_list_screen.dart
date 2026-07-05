import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/condition_history/domain/models/condition_history_model.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import '../providers/condition_history_list_provider.dart';

class ConditionHistoryListScreen extends ConsumerStatefulWidget {
  const ConditionHistoryListScreen({super.key});

  @override
  ConsumerState<ConditionHistoryListScreen> createState() =>
      _ConditionHistoryListScreenState();
}

class _ConditionHistoryListScreenState
    extends ConsumerState<ConditionHistoryListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(conditionHistoryListProvider.notifier).fetchHistories();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  Color _getConditionColor(String? conditionCode) {
    if (conditionCode == null) return AppTheme.primaryColor;
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
    return AppTheme.primaryColor;
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDay = DateTime(date.year, date.month, date.day);

    if (recordDay == today) return 'Hari ini';
    if (recordDay == yesterday) return 'Kemarin';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  bool get _hasActiveFilters {
    final state = ref.read(conditionHistoryListProvider);
    return state.conditionTypeId != null ||
        state.livestockId != null ||
        state.startDate != null ||
        state.endDate != null;
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conditionHistoryListProvider);
    final notifier = ref.read(conditionHistoryListProvider.notifier);
    final conditionTypesAsync = ref.watch(_conditionTypesProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Catatan Harian',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.scaffoldBackground,
        actions: [
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: () => notifier.clearFilters(),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(
                'Reset',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/condition-history/form'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Catat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // --- Header (Search & Filter) ---
          _buildSearchAndFilter(state, notifier, conditionTypesAsync),

          // --- List ---
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFF59E0B),
              onRefresh: () => notifier.fetchHistories(isRefresh: true),
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF59E0B),
                      ),
                    )
                  : state.histories.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 8, bottom: 100),
                          itemCount: state.histories.length +
                              (state.isLoadMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == state.histories.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              );
                            }
                            final item = state.histories[index];
                            return _buildHistoryCard(item);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================

  Widget _buildSearchAndFilter(
    ConditionHistoryListState state,
    ConditionHistoryListNotifier notifier,
    AsyncValue<List<Map<String, dynamic>>> conditionTypesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari nama ternak atau catatan...',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFFF59E0B)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          notifier.updateQuery('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: Color(0xFFF59E0B), width: 1.5),
                ),
              ),
              onSubmitted: (value) => notifier.updateQuery(value),
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips (Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Tombol Filter Tanggal
                _buildFilterChip(
                  label: state.startDate != null
                      ? '${DateFormat('dd/MM').format(state.startDate!)} - ${state.endDate != null ? DateFormat('dd/MM').format(state.endDate!) : '...'}'
                      : 'Semua Tanggal',
                  isSelected: state.startDate != null,
                  icon: Icons.calendar_month_rounded,
                  onTap: () => _showDateRangeFilter(context, notifier, state),
                ),
                const SizedBox(width: 8),

                // Divider
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 20,
                  width: 1.5,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 4),

                // Filter Kondisi (Dinamis dari API)
                conditionTypesAsync.when(
                  data: (types) {
                    if (types.isEmpty) return const SizedBox.shrink();

                    final selectedType = state.conditionTypeId != null
                        ? types.firstWhere(
                            (t) => t['id'] == state.conditionTypeId,
                            orElse: () => {},
                          )
                        : null;
                    final hasSelection = state.conditionTypeId != null;
                    final label = hasSelection && selectedType != null && selectedType.isNotEmpty
                        ? 'Kondisi: ${selectedType['label']}'
                        : 'Semua Kondisi';

                    return _buildFilterChip(
                      label: label,
                      isSelected: hasSelection,
                      icon: Icons.health_and_safety_outlined,
                      iconOnRight: true,
                      trailingIcon: Icons.keyboard_arrow_down_rounded,
                      onTap: () => _showConditionTypeFilter(
                          context, ref, types, notifier, state),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    bool iconOnRight = false,
    IconData? trailingIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && !iconOnRight) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (icon != null && iconOnRight) ...[
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ],
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(
                trailingIcon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ConditionHistoryModel item) {
    final conditionLabel =
        item.conditionType?['label'] as String? ?? 'Kondisi';
    final conditionCode =
        item.conditionType?['code'] as String? ?? '';
    final livestockName =
        item.livestock?['name'] as String? ?? 'Tanpa Nama';
    final livestockTag = item.livestock?['tagId'] as String?;

    final cardColor = _getConditionColor(conditionCode);
    final cardIcon = _getConditionIcon(conditionCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indikator Warna Kondisi (Kiri)
              Container(
                width: 5,
                color: cardColor,
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/condition-history/detail', extra: item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Ikon Kondisi
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              cardIcon,
                              color: cardColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Informasi Utama
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Nama Ternak
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        livestockName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (livestockTag != null) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Tag: $livestockTag',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(item.recordDate),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Badge Kondisi
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cardColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  conditionLabel.length > 12
                                      ? '${conditionLabel.substring(0, 12)}...'
                                      : conditionLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: cardColor,
                                  ),
                                ),
                              ),
                              if (item.notes != null &&
                                  item.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Icon(
                                  Icons.notes_rounded,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = ref.read(conditionHistoryListProvider).query.isNotEmpty ||
        _hasActiveFilters;
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.assignment_outlined,
                size: 72,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'Tidak Ada Hasil' : 'Belum Ada Catatan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                hasFilters
                    ? 'Coba ubah kata kunci pencarian atau filter yang Anda gunakan.'
                    : 'Mulai catat kondisi ternak Anda setiap hari untuk rekam jejak yang lebih baik.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM SHEETS & DIALOGS
  // ==========================================

  void _showDateRangeFilter(
    BuildContext context,
    ConditionHistoryListNotifier notifier,
    ConditionHistoryListState state,
  ) async {
    final now = DateTime.now();
    final initialRange = state.startDate != null
        ? DateTimeRange(
            start: state.startDate!,
            end: state.endDate ?? now,
          )
        : null;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF59E0B),
          ),
        ),
        child: child!,
      ),
      saveText: 'TERAPKAN',
    );

    if (picked != null) {
      notifier.updateDateRange(picked.start, picked.end);
    } else if (state.startDate != null) {
      // Jika ada filter sebelumnya dan user batal, bisa juga ditawarkan untuk reset
      // Tapi kita biarkan filter yang ada
    }
  }

  void _showConditionTypeFilter(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> types,
    ConditionHistoryListNotifier notifier,
    ConditionHistoryListState state,
  ) {
    String searchQuery = '';
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filtered = types.where((t) {
              final label = (t['label'] ?? '').toString().toLowerCase();
              return label.contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih Jenis Kondisi',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (state.conditionTypeId != null)
                            TextButton(
                              onPressed: () {
                                notifier.updateConditionTypeFilter(null);
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Reset',
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: textController,
                          onChanged: (val) =>
                              setStateSheet(() => searchQuery = val),
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari jenis kondisi...',
                            hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Kondisi tidak ditemukan',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              itemCount: filtered.length + 1,
                              itemBuilder: (context, idx) {
                                if (idx == 0) {
                                  final isAll =
                                      state.conditionTypeId == null;
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isAll
                                            ? const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.1)
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.all_inclusive_rounded,
                                        color: isAll
                                            ? const Color(0xFFF59E0B)
                                            : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Semua Kondisi',
                                      style: GoogleFonts.poppins(
                                        fontWeight: isAll
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isAll
                                            ? const Color(0xFFF59E0B)
                                            : AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isAll
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFFF59E0B),
                                          )
                                        : null,
                                    onTap: () {
                                      notifier
                                          .updateConditionTypeFilter(null);
                                      Navigator.pop(context);
                                    },
                                  );
                                }
                                final type = filtered[idx - 1];
                                final isSelected =
                                    state.conditionTypeId == type['id'];
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getConditionIcon(
                                          type['code'] as String?),
                                      color: isSelected
                                          ? const Color(0xFFF59E0B)
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    type['label'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFF59E0B)
                                          : AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFFF59E0B),
                                        )
                                      : null,
                                  onTap: () {
                                    notifier.updateConditionTypeFilter(
                                        type['id']);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// PROVIDER CONDITION TYPES (untuk filter)
// ============================================================================
final _conditionTypesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(farmRepositoryProvider);
  final response = await repo.getConditionTypes();
  return response;
});
