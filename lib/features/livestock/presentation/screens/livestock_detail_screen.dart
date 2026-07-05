import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
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

  @override
  void initState() {
    super.initState();
    // 2. Isi nilai awalnya dari parameter widget
    _currentLivestock = widget.livestock;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReferenceLabels();
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
                ],
              ),
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