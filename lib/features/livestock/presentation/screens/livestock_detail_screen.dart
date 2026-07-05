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
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete() async {
    setState(() => _isDeleting = true);
    try {
      final repo = ref.read(livestockRepositoryProvider);
      await repo.deleteLivestock(widget.livestock.id);
      
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

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Detail Ternak'),
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
          ? const Center(child: CircularProgressIndicator())
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
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                            isMale ? Icons.male : Icons.female,
                            size: 40,
                            color: isMale ? Colors.blue : Colors.pink,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.tagId ?? 'Tidak ada Tag',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                        Text('Informasi Detail', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Divider(height: 30),
                        _buildInfoRow('Status', item.status.toUpperCase()),
                        _buildInfoRow('Jenis Ternak', _animalTypeLabel),
                        _buildInfoRow('Jenis Kelamin', isMale ? 'Jantan' : 'Betina'),
                        _buildInfoRow(
                          'Tanggal Lahir',
                          item.birthDate != null ? DateFormat('dd MMMM yyyy').format(item.birthDate!) : '-',
                        ),
                        const Divider(height: 30),
                        Text('Silsilah (ID)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildInfoRow('Bapak (Pejantan)', _fatherLabel),
                        _buildInfoRow('Ibu (Induk)', _motherLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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