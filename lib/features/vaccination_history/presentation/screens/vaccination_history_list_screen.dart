import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import 'package:ternakku_app/features/vaccination_history/domain/models/vaccination_history_model.dart';
import '../providers/vaccination_history_list_provider.dart';

class VaccinationHistoryListScreen extends ConsumerStatefulWidget {
  final int? livestockId;
  final String? livestockName;

  const VaccinationHistoryListScreen({
    super.key,
    this.livestockId,
    this.livestockName,
  });

  @override
  ConsumerState<VaccinationHistoryListScreen> createState() =>
      _VaccinationHistoryListScreenState();
}

class _VaccinationHistoryListScreenState
    extends ConsumerState<VaccinationHistoryListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool get _isFilteredMode => widget.livestockId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFilteredMode) {
        _currentNotifier.updateLivestockFilter(widget.livestockId!);
      } else {
        _currentNotifier.clearFilters();
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(vaccinationHistoryListProvider.notifier).fetchHistories();
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDay = DateTime(date.year, date.month, date.day);

    if (recordDay == today) return 'Hari ini';
    if (recordDay == yesterday) return 'Kemarin';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  bool _isOverdue(VaccinationHistoryModel item) {
    if (item.isVaccinated) return false;
    return item.vaccinationDate.isBefore(DateTime.now());
  }

  bool _isUpcoming(VaccinationHistoryModel item) {
    if (item.isVaccinated) return false;
    final diff =
        item.vaccinationDate.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  Color _getStatusColor(VaccinationHistoryModel item) {
    if (item.isVaccinated) return const Color(0xFF22C55E);
    if (_isOverdue(item)) return const Color(0xFFEF4444);
    if (_isUpcoming(item)) return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
  }

  IconData _getStatusIcon(VaccinationHistoryModel item) {
    if (item.isVaccinated) return Icons.check_circle_rounded;
    if (_isOverdue(item)) return Icons.warning_amber_rounded;
    if (_isUpcoming(item)) return Icons.notification_important_rounded;
    return Icons.schedule_rounded;
  }

  String _getStatusLabel(VaccinationHistoryModel item) {
    if (item.isVaccinated) return 'Selesai';
    if (_isOverdue(item)) return 'Terlambat';
    if (_isUpcoming(item)) return 'Segera';
    return 'Terjadwal';
  }

  VaccinationHistoryListNotifier get _currentNotifier => ref.read(vaccinationHistoryListProvider.notifier);
  VaccinationHistoryListState get _currentState => ref.watch(vaccinationHistoryListProvider);

  bool get _hasActiveFilters {
    return _currentState.vaccineId != null ||
        _currentState.livestockId != null ||
        _currentState.isVaccinatedFilter != null ||
        _currentState.startDate != null ||
        _currentState.endDate != null;
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final vaccinesAsync = ref.watch(_vaccinesProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          _isFilteredMode
              ? 'Vaksinasi: ${widget.livestockName ?? 'Ternak'}'
              : 'Rekam Medis',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: _isFilteredMode ? 17 : 20,
            color: AppTheme.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.scaffoldBackground,
        actions: [
          if (_isFilteredMode
              ? (_currentState.vaccineId != null ||
                  _currentState.isVaccinatedFilter != null ||
                  _currentState.startDate != null ||
                  _currentState.endDate != null)
              : _hasActiveFilters)
            TextButton.icon(
              onPressed: () => _currentNotifier.clearFilters(isFilteredMode: _isFilteredMode),
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
        onPressed: () => context.push('/vaccination-history/form${_isFilteredMode ? '?livestockId=${widget.livestockId}' : ''}'),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Jadwalkan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // --- Header (Search & Filter) ---
          _buildSearchAndFilter(vaccinesAsync),

          // --- List ---
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFEF4444),
              onRefresh: () => _currentNotifier.fetchHistories(isRefresh: true),
              child: _currentState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEF4444),
                      ),
                    )
                  : _currentState.histories.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 8, bottom: 100),
                          itemCount: _currentState.histories.length +
                              (_currentState.isLoadMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == _currentState.histories.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              );
                            }
                            final item = _currentState.histories[index];
                            return _buildVaccinationCard(item);
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
    AsyncValue<List<Map<String, dynamic>>> vaccinesAsync,
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
                hintText: 'Cari nama ternak atau vaksin...',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFFEF4444)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _currentNotifier.updateQuery('');
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
                  borderSide:
                      const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
              ),
              onSubmitted: (value) => _currentNotifier.updateQuery(value),
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips (Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Filter Tanggal
                _buildFilterChip(
                  label: _currentState.startDate != null
                      ? '${DateFormat('dd/MM').format(_currentState.startDate!)} - ${_currentState.endDate != null ? DateFormat('dd/MM').format(_currentState.endDate!) : '...'}'
                      : 'Semua Tanggal',
                  isSelected: _currentState.startDate != null,
                  icon: Icons.calendar_month_rounded,
                  onTap: () => _showDateRangeFilter(context),
                ),
                const SizedBox(width: 8),

                // Filter Status Vaksinasi
                _buildFilterChip(
                  label: _currentState.isVaccinatedFilter == null
                      ? 'Semua Status'
                      : _currentState.isVaccinatedFilter!
                          ? 'Sudah Vaksin'
                          : 'Belum Vaksin',
                  isSelected: _currentState.isVaccinatedFilter != null,
                  icon: Icons.vaccines_rounded,
                  onTap: () => _showVaccinatedFilter(context),
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

                // Filter Vaksin (Dinamis dari API)
                vaccinesAsync.when(
                  data: (vaccines) {
                    if (vaccines.isEmpty) return const SizedBox.shrink();

                    final selectedVaccine = _currentState.vaccineId != null
                        ? vaccines.firstWhere(
                            (v) => v['id'] == _currentState.vaccineId,
                            orElse: () => {},
                          )
                        : null;
                    final hasSelection = _currentState.vaccineId != null;
                    final label = hasSelection &&
                            selectedVaccine != null &&
                            selectedVaccine.isNotEmpty
                        ? 'Vaksin: ${selectedVaccine['name']}'
                        : 'Semua Vaksin';

                    return _buildFilterChip(
                      label: label,
                      isSelected: hasSelection,
                      icon: Icons.medication_rounded,
                      iconOnRight: true,
                      trailingIcon: Icons.keyboard_arrow_down_rounded,
                      onTap: () => _showVaccineFilter(
                          context, ref, vaccines),
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
    const accentColor = Color(0xFFEF4444);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
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

  Widget _buildVaccinationCard(
    VaccinationHistoryModel item,
  ) {
    final vaccineName =
        item.vaccine?['name'] as String? ?? 'Vaksin';
    final livestockName =
        item.livestock?['name'] as String? ?? 'Tanpa Nama';
    final livestockTag = item.livestock?['tagId'] as String?;

    final statusColor = _getStatusColor(item);
    final statusIcon = _getStatusIcon(item);
    final statusLabel = _getStatusLabel(item);

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
              // Indikator Warna Status (Kiri)
              Container(
                width: 5,
                color: statusColor,
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/vaccination-history/detail', extra: item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          // Ikon Status
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

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
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (livestockTag != null) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
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
                                const SizedBox(height: 4),
                                // Nama Vaksin
                                Row(
                                  children: [
                                    Icon(
                                      Icons.vaccines_rounded,
                                      size: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        vaccineName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Tanggal Vaksinasi
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(item.vaccinationDate),
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

                          // Kolom Kanan: Badge Status + Tombol Mark
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Badge Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              // Tombol "Tandai Vaksin" jika belum divaksin
                              if (!item.isVaccinated) ...[
                                const SizedBox(height: 8),
                                _MarkVaccinatedButton(
                                  item: item,
                                  notifier: _currentNotifier,
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
    final hasFilters = ref.read(vaccinationHistoryListProvider).query.isNotEmpty ||
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
                color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.medical_services_outlined,
                size: 72,
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'Tidak Ada Hasil' : 'Belum Ada Rekam Medis',
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
                    : 'Mulai jadwalkan vaksinasi untuk memastikan kesehatan ternak Anda terjaga.',
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
  ) async {
    final now = DateTime.now();
    final initialRange = _currentState.startDate != null
        ? DateTimeRange(
            start: _currentState.startDate!,
            end: _currentState.endDate ?? now,
          )
        : null;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEF4444),
          ),
        ),
        child: child!,
      ),
      saveText: 'TERAPKAN',
    );

    if (picked != null) {
      _currentNotifier.updateDateRange(picked.start, picked.end);
    }
  }

  void _showVaccinatedFilter(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Status Vaksinasi',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_currentState.isVaccinatedFilter != null)
                    TextButton(
                      onPressed: () {
                        _currentNotifier.updateIsVaccinatedFilter(null);
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
              const SizedBox(height: 8),
              ...[
                _buildStatusFilterTile(
                  context: context,
                  label: 'Semua Status',
                  icon: Icons.all_inclusive_rounded,
                  color: Colors.grey,
                  isSelected: _currentState.isVaccinatedFilter == null,
                  onTap: () {
                    _currentNotifier.updateIsVaccinatedFilter(null);
                    Navigator.pop(context);
                  },
                ),
                _buildStatusFilterTile(
                  context: context,
                  label: 'Sudah Divaksinasi',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF22C55E),
                  isSelected: _currentState.isVaccinatedFilter == true,
                  onTap: () {
                    _currentNotifier.updateIsVaccinatedFilter(true);
                    Navigator.pop(context);
                  },
                ),
                _buildStatusFilterTile(
                  context: context,
                  label: 'Belum Divaksinasi',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFEF4444),
                  isSelected: _currentState.isVaccinatedFilter == false,
                  onTap: () {
                    _currentNotifier.updateIsVaccinatedFilter(false);
                    Navigator.pop(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFFEF4444) : AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFEF4444))
          : null,
      onTap: onTap,
    );
  }

  void _showVaccineFilter(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> vaccines,
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
            final filtered = vaccines.where((v) {
              final name = (v['name'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
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
                            'Pilih Jenis Vaksin',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (_currentState.vaccineId != null)
                            TextButton(
                              onPressed: () {
                                _currentNotifier.updateVaccineFilter(null);
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
                            hintText: 'Cari jenis vaksin...',
                            hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.grey),
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
                                'Vaksin tidak ditemukan',
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
                                  final isAll = _currentState.vaccineId == null;
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isAll
                                            ? const Color(0xFFEF4444)
                                                .withValues(alpha: 0.1)
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.all_inclusive_rounded,
                                        color: isAll
                                            ? const Color(0xFFEF4444)
                                            : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Semua Vaksin',
                                      style: GoogleFonts.poppins(
                                        fontWeight: isAll
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isAll
                                            ? const Color(0xFFEF4444)
                                            : AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isAll
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFFEF4444),
                                          )
                                        : null,
                                    onTap: () {
                                      _currentNotifier.updateVaccineFilter(null);
                                      Navigator.pop(context);
                                    },
                                  );
                                }
                                final vaccine = filtered[idx - 1];
                                final isSelected =
                                    _currentState.vaccineId == vaccine['id'];
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEF4444)
                                              .withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.vaccines_rounded,
                                      color: isSelected
                                          ? const Color(0xFFEF4444)
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    vaccine['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFEF4444)
                                          : AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFFEF4444),
                                        )
                                      : null,
                                  onTap: () {
                                    _currentNotifier.updateVaccineFilter(vaccine['id']);
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
// WIDGET TOMBOL "TANDAI SUDAH DIVAKSINASI"
// ============================================================================
class _MarkVaccinatedButton extends ConsumerStatefulWidget {
  final VaccinationHistoryModel item;
  final VaccinationHistoryListNotifier notifier;

  const _MarkVaccinatedButton({
    required this.item,
    required this.notifier,
  });

  @override
  ConsumerState<_MarkVaccinatedButton> createState() =>
      _MarkVaccinatedButtonState();
}

class _MarkVaccinatedButtonState
    extends ConsumerState<_MarkVaccinatedButton> {
  bool _isLoading = false;

  Future<void> _markVaccinated() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Vaksinasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tandai vaksinasi ini sebagai selesai?',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Ya, Tandai',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await widget.notifier.markAsVaccinated(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaksinasi berhasil ditandai selesai ✓'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menandai vaksinasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _markVaccinated,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _isLoading
              ? Colors.grey.shade100
              : const Color(0xFF22C55E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isLoading
                ? Colors.grey.shade300
                : const Color(0xFF22C55E).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF22C55E),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tandai',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// PROVIDER VACCINES (untuk filter)
// ============================================================================
final _vaccinesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(farmRepositoryProvider);
  return await repo.getVaccines();
});
