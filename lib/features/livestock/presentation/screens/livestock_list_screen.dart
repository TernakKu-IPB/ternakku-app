import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/livestock/presentation/providers/livestock_form_provider.dart';
import '../../domain/models/livestock_model.dart';
import '../providers/livestock_list_provider.dart';

class LivestockListScreen extends ConsumerStatefulWidget {
  const LivestockListScreen({super.key});

  @override
  ConsumerState<LivestockListScreen> createState() => _LivestockListScreenState();
}

class _LivestockListScreenState extends ConsumerState<LivestockListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(livestockListProvider.notifier).fetchLivestocks();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'sold':
        return 'Terjual';
      case 'dead':
        return 'Mati';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livestockListProvider);
    final notifier = ref.read(livestockListProvider.notifier);
    
    final animalTypesAsync = ref.watch(farmAnimalTypesProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Inventaris Ternak',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.scaffoldBackground,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/livestock/form'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // --- Bagian Header (Search & Filter) ---
          Container(
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
                      hintText: 'Cari nama atau tag ID...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
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
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      ),
                    ),
                    onSubmitted: (value) => notifier.updateQuery(value),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Chips (Scrollable Horizontal)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', state.status == null && state.animalTypeId == null && state.gender == null, () {
                        notifier.updateStatus(null);
                        notifier.updateGender(null);
                        notifier.updateAnimalType(-1);
                      }),
                      const SizedBox(width: 8),                      
                      _buildFilterChip(
                        'Aktif', 
                        state.status == 'active', 
                        () => notifier.updateStatus(state.status == 'active' ? null : 'active')
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Terjual', 
                        state.status == 'sold', 
                        () => notifier.updateStatus(state.status == 'sold' ? null : 'sold')
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Mati', 
                        state.status == 'dead', 
                        () => notifier.updateStatus(state.status == 'dead' ? null : 'dead')
                      ),
                      
                      // Divider vertikal kecil
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        height: 20,
                        width: 1.5,
                        color: Colors.grey.shade300,
                      ),

                      // --- FILTER JENIS TERNAK (DINAMIS API DENGAN BOTTOM SHEET MODERN) ---
                      animalTypesAsync.when(
                        data: (types) {
                          if (types.isEmpty) return const SizedBox.shrink();

                          final selectedType = types.firstWhere(
                            (type) => type['id'] == state.animalTypeId,
                            orElse: () => {},
                          );
                          final hasSelection = state.animalTypeId != null;
                          final displayLabel = hasSelection ? 'Jenis: ${selectedType['label']}' : 'Semua Jenis';

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildFilterChip(
                              displayLabel,
                              hasSelection,
                              () => _showAnimalTypeFilterBottomSheet(context, ref, types),
                              icon: Icons.keyboard_arrow_down_rounded,
                              iconColor: hasSelection ? Colors.white : Colors.grey.shade600,
                              iconOnRight: true,
                            ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        height: 20,
                        width: 1.5,
                        color: Colors.grey.shade300,
                      ),
                      
                      // Filter Gender
                      _buildFilterChip(
                        'Jantan',
                        state.gender == 'male',
                        () => notifier.updateGender(state.gender == 'male' ? null : 'male'),
                        icon: Icons.male,
                        iconColor: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Betina',
                        state.gender == 'female',
                        () => notifier.updateGender(state.gender == 'female' ? null : 'female'),
                        icon: Icons.female,
                        iconColor: Colors.pink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Bagian List ---
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () => notifier.fetchLivestocks(isRefresh: true),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.livestocks.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 90),
                          itemCount: state.livestocks.length + (state.isLoadMore ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == state.livestocks.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final item = state.livestocks[index];
                            return _buildLivestockCard(item);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components Khusus ---

  void _showAnimalTypeFilterBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> types,
  ) {
    final notifier = ref.read(livestockListProvider.notifier);
    final state = ref.read(livestockListProvider);
    String searchQuery = '';
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            final filteredTypes = types.where((type) {
              final label = type['label'].toString().toLowerCase();
              return label.contains(searchQuery.toLowerCase());
            }).toList();

            IconData getAnimalIcon(String label) {
              final lowerLabel = label.toLowerCase();
              if (lowerLabel.contains('sapi') || lowerLabel.contains('cow')) {
                return Icons.pets_rounded;
              } else if (lowerLabel.contains('kambing') || lowerLabel.contains('goat')) {
                return Icons.eco_rounded;
              } else if (lowerLabel.contains('domba') || lowerLabel.contains('sheep')) {
                return Icons.cloud_queue_rounded;
              } else if (lowerLabel.contains('ayam') || lowerLabel.contains('chicken') || lowerLabel.contains('unggas')) {
                return Icons.egg_rounded;
              } else if (lowerLabel.contains('bebek') || lowerLabel.contains('duck')) {
                return Icons.water_drop_rounded;
              } else if (lowerLabel.contains('kelinci') || lowerLabel.contains('rabbit')) {
                return Icons.pets_rounded;
              }
              return Icons.pets_rounded;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    // Drag Handle Indicator
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Header Sheet
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih Jenis Ternak',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (state.animalTypeId != null)
                            TextButton(
                              onPressed: () {
                                notifier.updateAnimalType(-1);
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
                    const SizedBox(height: 16),

                    // Search Bar inside sheet
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: textController,
                          onChanged: (val) {
                            setStateBottomSheet(() {
                              searchQuery = val;
                            });
                          },
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari jenis ternak...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List of Options
                    Expanded(
                      child: filteredTypes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Jenis ternak tidak ditemukan',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredTypes.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  final isAllSelected = state.animalTypeId == null;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isAllSelected 
                                            ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.all_inclusive_rounded,
                                        color: isAllSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Semua Jenis Ternak',
                                      style: GoogleFonts.poppins(
                                        fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isAllSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isAllSelected
                                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                                        : null,
                                    onTap: () {
                                      notifier.updateAnimalType(-1);
                                      Navigator.pop(context);
                                    },
                                  );
                                }

                                final type = filteredTypes[index - 1];
                                final isSelected = state.animalTypeId == type['id'];

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      getAnimalIcon(type['label']),
                                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    type['label'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                                      : null,
                                  onTap: () {
                                    notifier.updateAnimalType(type['id']);
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

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
    Color? iconColor,
    bool iconOnRight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                size: 16,
                color: isSelected ? Colors.white : (iconColor ?? Colors.grey.shade600),
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
                size: 16,
                color: isSelected ? Colors.white : (iconColor ?? Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 72, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak Ada Data Ternak',
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
                'Cobalah cari dengan kata kunci lain atau ubah filter status yang Anda pilih.',
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

  Widget _buildLivestockCard(LivestockModel item) {
    Color statusColor = Colors.grey;
    if (item.status == 'active') statusColor = AppTheme.secondaryColor;
    if (item.status == 'sold') statusColor = Colors.blue;
    if (item.status == 'dead') statusColor = Colors.red;

    final isMale = item.gender == 'male';

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
              // Garis Indikator Status di Sebelah Kiri
              Container(
                width: 5,
                color: statusColor,
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/livestock/detail', extra: item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Avatar / Gambar Ternak
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: item.picture != null && item.picture!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(item.picture!, fit: BoxFit.cover),
                                  )
                                : Icon(
                                    Icons.pets_rounded,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                                    size: 28,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Informasi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name ?? 'Tanpa Nama',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Icon Gender
                                    Icon(
                                      isMale ? Icons.male_rounded : Icons.female_rounded,
                                      color: isMale ? Colors.blue : Colors.pink,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Tag: ${item.tagId ?? '-'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Badge Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(item.status).toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
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
}