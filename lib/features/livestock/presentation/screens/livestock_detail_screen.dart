import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/condition_history/data/repositories/condition_history_repository.dart';
import 'package:ternakku_app/features/condition_history/domain/models/condition_history_model.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import 'package:ternakku_app/features/vaccination_history/data/repositories/vaccination_history_repository.dart';
import 'package:ternakku_app/features/vaccination_history/domain/models/vaccination_history_model.dart';
import '../../domain/models/livestock_model.dart';
import '../../data/repositories/livestock_repository.dart';
import '../providers/livestock_list_provider.dart';

class LivestockDetailScreen extends ConsumerStatefulWidget {
  final LivestockModel livestock;

  const LivestockDetailScreen({super.key, required this.livestock});

  @override
  ConsumerState<LivestockDetailScreen> createState() => _LivestockDetailScreenState();
}

class _LivestockDetailScreenState extends ConsumerState<LivestockDetailScreen> {
  bool _isDeleting = false;

  late LivestockModel _currentLivestock;

  String _animalTypeLabel = 'Memuat...';
  String _fatherLabel = '-';
  String _motherLabel = '-';

  // --- State kondisi terkini ---
  ConditionHistoryModel? _latestCondition;
  bool _isLoadingCondition = true;
  String _conditionTypeLabel = '-';

  // --- State riwayat vaksinasi ---
  VaccinationHistoryModel? _latestVaccination;
  bool _isLoadingVaccination = true;
  String _vaccineLabel = '-';

  @override
  void initState() {
    super.initState();
    // 2. Isi nilai awalnya dari parameter widget
    _currentLivestock = widget.livestock;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReferenceLabels();
      _loadLatestCondition();
      _loadLatestVaccination();
    });
  }

  // ==========================================
  // HELPERS
  // ==========================================

  Color get _getStatusColor {
    final lower = _currentLivestock.status.toLowerCase();
    if (lower.contains('active') || lower.contains('alive')) {
      return AppTheme.secondaryColor;
    } else if (lower.contains('sold')) {
      return Colors.blue;
    } else if (lower.contains('dead') || lower.contains('deceased')) {
      return Colors.red;
    }
    return AppTheme.primaryColor;
  }

  // IconData _getStatusIcon(String? status) {
  //   if (status == null) return Icons.help_outline_rounded;
  //   final lower = status.toLowerCase();
  //   if (lower.contains('active') || lower.contains('alive')) {
  //     return Icons.check_circle_rounded;
  //   } else if (lower.contains('sold')) {
  //     return Icons.sell_rounded;
  //   } else if (lower.contains('dead') || lower.contains('deceased')) {
  //     return Icons.dangerous_rounded;
  //   }
  //   return Icons.help_outline_rounded;
  // }

  String get _getStatusLabel {
    switch (_currentLivestock.status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'sold':
        return 'Terjual';
      case 'dead':
        return 'Mati';
      default:
        return _currentLivestock.status;
    }
  }

  IconData get _getAnimalIcon {
    final lowerLabel = _currentLivestock.status.toLowerCase();
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
  

  // ==========================================
  // FETCH LABEL ASLI
  // ==========================================
  Future<void> _loadReferenceLabels() async {
    final item = _currentLivestock;
    final livestockRepo = ref.read(livestockRepositoryProvider);
    
    final farmRepo = ref.read(farmRepositoryProvider); 

    // 1. Ambil nama Jenis Ternak
    try {
      if (mounted) setState(() => _animalTypeLabel = 'Memuat...');
      final animalType = await farmRepo.getAnimalTypeDetail(item.animalTypeId);
      if (mounted) {
        setState(() {
          _animalTypeLabel = animalType['label'] ?? 'ID: ${item.animalTypeId}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _animalTypeLabel = 'ID: ${item.animalTypeId}');
    }

    // 2. Ambil data Pejantan (Bapak)
    if (item.fatherId != null) {
      try {
        if (mounted) setState(() => _fatherLabel = 'Memuat...');
        final father = await livestockRepo.getLivestockDetail(item.fatherId!);
        if (mounted) {
          setState(() {
            _fatherLabel = '${father.name ?? 'Tanpa Nama'} (${father.tagId ?? '-'})';
          });
        }
      } catch (e) {
        if (mounted) setState(() => _fatherLabel = 'ID: ${item.fatherId}');
      }
    } else {
      if (mounted) setState(() => _fatherLabel = '-');
    }

    // 3. Ambil data Induk (Ibu)
    if (item.motherId != null) {
      try {
        if (mounted) setState(() => _motherLabel = 'Memuat...');
        final mother = await livestockRepo.getLivestockDetail(item.motherId!);
        if (mounted) {
          setState(() {
            _motherLabel = '${mother.name ?? 'Tanpa Nama'} (${mother.tagId ?? '-'})';
          });
        }
      } catch (e) {
        if (mounted) setState(() => _motherLabel = 'ID: ${item.motherId}');
      }
    } else {
      if (mounted) setState(() => _motherLabel = '-');
    }
  }

  // ==========================================
  // FETCH KONDISI TERKINI
  // ==========================================
  Future<void> _loadLatestCondition() async {
    if (!mounted) return;
    setState(() => _isLoadingCondition = true);

    try {
      final repo = ref.read(conditionHistoryRepositoryProvider);
      final results = await repo.getConditionHistories(
        limit: 1,
        offset: 0,
        livestockId: _currentLivestock.id,
      );

      if (!mounted) return;

      if (results.isNotEmpty) {
        final latest = results.first;
        // Ambil label tipe kondisi
        String condLabel = '-';
        if (latest.conditionType != null && latest.conditionType!.isNotEmpty) {
          condLabel = latest.conditionType!['label'] as String? ?? '-';
        } else {
          try {
            final farmRepo = ref.read(farmRepositoryProvider);
            final ct = await farmRepo.getConditionTypeDetail(latest.conditionTypeId);
            condLabel = ct['label'] as String? ?? '-';
          } catch (_) {
            condLabel = 'ID: ${latest.conditionTypeId}';
          }
        }

        if (mounted) {
          setState(() {
            _latestCondition = latest;
            _conditionTypeLabel = condLabel;
            _isLoadingCondition = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingCondition = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCondition = false);
    }
  }

  // ==========================================
  // HELPERS KONDISI
  // ==========================================
  Color _getConditionColor(String conditionLabel) {
    final lower = conditionLabel.toLowerCase();
    if (lower.contains('sehat') || lower.contains('baik') || lower.contains('normal')) {
      return const Color(0xFF22C55E);
    } else if (lower.contains('sakit') || lower.contains('ill') || lower.contains('sick')) {
      return const Color(0xFFEF4444);
    } else if (lower.contains('lahir') || lower.contains('birth')) {
      return const Color(0xFF3B82F6);
    } else if (lower.contains('mati') || lower.contains('dead')) {
      return const Color(0xFF6B7280);
    } else if (lower.contains('bunting') || lower.contains('hamil') || lower.contains('pregnant')) {
      return const Color(0xFFF59E0B);
    }
    return AppTheme.primaryColor;
  }

  IconData _getConditionIcon(String conditionLabel) {
    final lower = conditionLabel.toLowerCase();
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

  String _formatDateRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDay = DateTime(date.year, date.month, date.day);

    if (recordDay == today) return 'Hari ini';
    if (recordDay == yesterday) return 'Kemarin';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Ternak?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data ${widget.livestock.name ?? 'ternak ini'}? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete() async {
    setState(() => _isDeleting = true);
    try {
      await ref
        .read(livestockRepositoryProvider)
        .deleteLivestock(widget.livestock.id);
      
      if (mounted) {
        // Refresh daftar list ternak di background
        ref.read(livestockListProvider.notifier).fetchLivestocks(isRefresh: true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data ternak berhasil dihapus'), backgroundColor: AppTheme.secondaryColor),
        );
        
        // Kembali ke halaman list
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus data ternak'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentLivestock;
    final isMale = item.gender == 'male';
    final color = _getStatusColor;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Detail Ternak',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.scaffoldBackground,
        actions: [
          // Tombol Edit
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
            onPressed: () async {
              // Lempar data ke form untuk di-edit
              final updatedItem = await context.push<LivestockModel?>('/livestock/form', extra: item);
              if (updatedItem != null) {
                setState(() {
                  _currentLivestock = updatedItem;
                });
                _loadReferenceLabels();
              }
            },
          ),
          // Tombol Hapus
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isDeleting ? null : _showDeleteDialog,
          ),
        ],
      ),
      body: _isDeleting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Menghapus ternak...',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- KARTU HEADER ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getAnimalIcon,
                            size: 38,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          textAlign: TextAlign.center,
                          item.name ?? 'Tanpa Nama',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.tagId ?? 'Tidak ada Tag',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- KARTU INFORMASI ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Informasi Detail',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        _buildInfoRow(
                          Icons.verified_rounded,
                          'Status',
                          _getStatusLabel,
                        ),
                        _buildInfoRow(
                          Icons.pets_rounded,
                          'Jenis Ternak',
                          _animalTypeLabel,
                        ),
                        _buildInfoRow(
                          isMale ? Icons.male_rounded : Icons.female_rounded,
                          'Jenis Kelamin',
                          isMale ? 'Jantan' : 'Betina',
                        ),
                        _buildInfoRow(
                          Icons.cake_rounded,
                          'Tanggal Lahir',
                          item.birthDate != null
                              ? DateFormat('dd MMMM yyyy', 'id_ID')
                                .format(item.birthDate!)
                              : '-',
                        ),
                      ],
                    ),
                  ),

                  if (item.fatherId != null || item.motherId != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_tree_rounded,
                                color: color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Silsilah',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ]
                          ),
                          const Divider(height: 28),
                          _buildInfoRow(
                            Icons.man_rounded,
                            'Bapak (Pejantan)',
                            _fatherLabel,
                          ),
                          _buildInfoRow(
                            Icons.woman_rounded,
                            'Ibu (Induk)',
                            _motherLabel,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- KARTU KONDISI TERKINI ---
                  const SizedBox(height: 16),
                  _buildLatestConditionCard(color),

                  // --- KARTU VAKSINASI TERAKHIR ---
                  const SizedBox(height: 16),
                  _buildLatestVaccinationCard(color),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // KARTU KONDISI TERKINI
  // ==========================================
  Widget _buildLatestConditionCard(Color livestockColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart_rounded,
                  color: livestockColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kondisi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Tombol "Lihat Riwayat Lengkap"
                GestureDetector(
                  onTap: () async {
                    await context.push(
                      '/condition-history',
                      extra: {
                        'livestockId': _currentLivestock.id,
                        'livestockName': _currentLivestock.name ?? 'Ternak',
                      },
                    );

                    _loadLatestCondition();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: livestockColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: livestockColor,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: livestockColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 24),
          ),

          // Konten kondisi
          if (_isLoadingCondition)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: livestockColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Memuat kondisi...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else if (_latestCondition == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belum Ada Catatan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap "Lihat Semua" untuk mulai mencatat kondisi ternak ini.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            _buildConditionContent(_latestCondition!, livestockColor),
        ],
      ),
    );
  }

  Widget _buildConditionContent(ConditionHistoryModel condition, Color livestockColor) {
    final condColor = _getConditionColor(_conditionTypeLabel);
    final condIcon = _getConditionIcon(_conditionTypeLabel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris utama: ikon + label kondisi + tanggal
          Row(
            children: [
              // Ikon kondisi
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: condColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  condIcon,
                  color: condColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge kondisi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: condColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _conditionTypeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: condColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Tanggal
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateRelative(condition.recordDate),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tap untuk detail
              IconButton(
                onPressed: () async {
                  await context.push('/condition-history/detail', extra: condition);
                  _loadLatestCondition();
                },
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                tooltip: 'Lihat Detail',
              ),
            ],
          ),

          // Catatan tambahan (jika ada)
          if (condition.notes != null && condition.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: condColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: condColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: condColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      condition.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textPrimary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // FETCH VAKSINASI TERKINI
  // ==========================================
  Future<void> _loadLatestVaccination() async {
    if (!mounted) return;
    setState(() => _isLoadingVaccination = true);

    try {
      final repo = ref.read(vaccinationHistoryRepositoryProvider);
      final results = await repo.getVaccinationHistories(
        limit: 1,
        offset: 0,
        livestockId: _currentLivestock.id,
      );

      if (!mounted) return;

      if (results.isNotEmpty) {
        final latest = results.first;
        String vacLabel = '-';
        if (latest.vaccine != null && latest.vaccine!.isNotEmpty) {
          vacLabel = latest.vaccine!['name'] as String? ?? '-';
        } else {
          try {
            final farmRepo = ref.read(farmRepositoryProvider);
            final v = await farmRepo.getVaccineDetail(latest.vaccineId);
            vacLabel = v['name'] as String? ?? '-';
          } catch (_) {
            vacLabel = 'ID: ${latest.vaccineId}';
          }
        }

        if (mounted) {
          setState(() {
            _latestVaccination = latest;
            _vaccineLabel = vacLabel;
            _isLoadingVaccination = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingVaccination = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVaccination = false);
    }
  }

  int _daysUntilVaccination(VaccinationHistoryModel item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final vaccinationDate = DateTime(
      item.vaccinationDate.year,
      item.vaccinationDate.month,
      item.vaccinationDate.day,
    );

    return vaccinationDate.difference(today).inDays;
  }

  bool _isToday(VaccinationHistoryModel item) {
    if (item.isVaccinated) return false;
    return _daysUntilVaccination(item) == 0;
  }

  bool _isOverdue(VaccinationHistoryModel item) {
    if (item.isVaccinated) return false;
    return _daysUntilVaccination(item) < 0;
  }

  bool _isUpcoming(VaccinationHistoryModel item) {
    if (item.isVaccinated) return false;
    final diff = _daysUntilVaccination(item);
    return diff > 0 && diff <= 7;
  }

  Color _getVaccinationColor(VaccinationHistoryModel item) {
    if (item.isVaccinated) return const Color(0xFF22C55E); // Hijau
    if (_isToday(item)) return const Color(0xFFF97316); // Oranye
    if (_isOverdue(item)) return const Color(0xFFEF4444); // Merah
    if (_isUpcoming(item)) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF3B82F6); // Biru
  }

  IconData _getVaccinationIcon(VaccinationHistoryModel item) {
    if (item.isVaccinated) return Icons.check_circle_rounded;
    if (_isToday(item)) return Icons.today_rounded;
    if (_isOverdue(item)) return Icons.warning_amber_rounded;
    if (_isUpcoming(item)) return Icons.notification_important_rounded;
    return Icons.schedule_rounded;
  }

  String _getVaccinationStatusLabel(VaccinationHistoryModel item) {
    if (item.isVaccinated) return 'Selesai';
    if (_isToday(item)) return 'Hari Ini';
    if (_isOverdue(item)) return 'Terlambat';
    if (_isUpcoming(item)) return 'Segera';
    return 'Terjadwal';
  }

  Widget _buildLatestVaccinationCard(Color livestockColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.vaccines_rounded,
                  color: livestockColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vaksinasi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Tombol "Lihat Semua"
                GestureDetector(
                  onTap: () async {
                    await context.push(
                      '/vaccination-history',
                      extra: {
                        'livestockId': _currentLivestock.id,
                        'livestockName': _currentLivestock.name ?? 'Ternak',
                      },
                    );

                    _loadLatestVaccination();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: livestockColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: livestockColor,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: livestockColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 24),
          ),

          // Konten vaksinasi
          if (_isLoadingVaccination)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: livestockColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Memuat riwayat vaksinasi...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else if (_latestVaccination == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belum Ada Catatan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap "Lihat Semua" untuk mulai mencatat riwayat vaksinasi.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            _buildVaccinationContent(_latestVaccination!, livestockColor),
        ],
      ),
    );
  }

  Widget _buildVaccinationContent(VaccinationHistoryModel vaccination, Color livestockColor) {
    final vacColor = _getVaccinationColor(vaccination);
    final vacIcon = _getVaccinationIcon(vaccination);
    final statusLabel = _getVaccinationStatusLabel(vaccination);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris utama: ikon + label vaksin + tanggal
          Row(
            children: [
              // Ikon status vaksin
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: vacColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  vacIcon,
                  color: vacColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Vaksin
                    Text(
                      _vaccineLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Badge status vaksinasi
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: vacColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: vacColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateRelative(vaccination.vaccinationDate),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tap untuk detail
              IconButton(
                onPressed: () async {
                  await context.push('/vaccination-history/detail', extra: vaccination);
                  _loadLatestVaccination();
                },
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                tooltip: 'Lihat Detail',
              ),
            ],
          ),

          // Catatan tambahan / Batch number (jika ada)
          if ((vaccination.batchNumber != null && vaccination.batchNumber!.isNotEmpty) ||
              (vaccination.notes != null && vaccination.notes!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: vacColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: vacColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vaccination.batchNumber != null && vaccination.batchNumber!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_rounded,
                          size: 12,
                          color: vacColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Batch: ${vaccination.batchNumber}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    if (vaccination.notes != null && vaccination.notes!.isNotEmpty)
                      const SizedBox(height: 6),
                  ],
                  if (vaccination.notes != null && vaccination.notes!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 12,
                          color: vacColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vaccination.notes!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textPrimary.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}