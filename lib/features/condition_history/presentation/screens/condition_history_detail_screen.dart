import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/condition_history/data/repositories/condition_history_repository.dart';
import 'package:ternakku_app/features/condition_history/domain/models/condition_history_model.dart';
import 'package:ternakku_app/features/condition_history/presentation/providers/condition_history_list_provider.dart';
import 'package:ternakku_app/features/livestock/data/repositories/livestock_repository.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';

class ConditionHistoryDetailScreen extends ConsumerStatefulWidget {
  final ConditionHistoryModel history;

  const ConditionHistoryDetailScreen({super.key, required this.history});

  @override
  ConsumerState<ConditionHistoryDetailScreen> createState() =>
      _ConditionHistoryDetailScreenState();
}

class _ConditionHistoryDetailScreenState
    extends ConsumerState<ConditionHistoryDetailScreen> {
  bool _isDeleting = false;
  late ConditionHistoryModel _current;

  // Labels yang di-fetch dari API
  String _livestockLabel = '-';
  String _conditionTypeLabel = '-';

  @override
  void initState() {
    super.initState();
    _current = widget.history;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLabels();
    });
  }

  // ==========================================
  // HELPERS
  // ==========================================

  Color get _conditionColor {
    final code = _conditionTypeLabel.toLowerCase();
    if (code.contains('sehat') || code.contains('baik') || code.contains('normal')) {
      return const Color(0xFF22C55E);
    } else if (code.contains('sakit') || code.contains('ill') || code.contains('sick')) {
      return const Color(0xFFEF4444);
    } else if (code.contains('lahir') || code.contains('birth')) {
      return const Color(0xFF3B82F6);
    } else if (code.contains('mati') || code.contains('dead')) {
      return const Color(0xFF6B7280);
    } else if (code.contains('bunting') || code.contains('hamil')) {
      return const Color(0xFFF59E0B);
    }
    return AppTheme.primaryColor;
  }

  IconData get _conditionIcon {
    final code = _conditionTypeLabel.toLowerCase();
    if (code.contains('sehat') || code.contains('baik') || code.contains('normal')) {
      return Icons.favorite_rounded;
    } else if (code.contains('sakit') || code.contains('ill') || code.contains('sick')) {
      return Icons.sick_rounded;
    } else if (code.contains('lahir') || code.contains('birth')) {
      return Icons.child_care_rounded;
    } else if (code.contains('mati') || code.contains('dead')) {
      return Icons.heart_broken_rounded;
    } else if (code.contains('bunting') || code.contains('hamil')) {
      return Icons.pregnant_woman_rounded;
    }
    return Icons.note_alt_outlined;
  }

  // ==========================================
  // DATA LOADING
  // ==========================================

  Future<void> _loadLabels() async {
    final item = _current;

    // Jika relasi sudah ada di model, gunakan langsung
    if (item.livestock != null && item.livestock!.isNotEmpty) {
      final name = item.livestock!['name'] as String? ?? 'Tanpa Nama';
      final tag = item.livestock!['tagId'] as String?;
      if (mounted) {
        setState(() {
          _livestockLabel = tag != null ? '$name (Tag: $tag)' : name;
        });
      }
    } else {
      // Fetch dari API jika tidak ada
      try {
        final repo = ref.read(livestockRepositoryProvider);
        final ls = await repo.getLivestockDetail(item.livestockId);
        if (mounted) {
          setState(() {
            final tag = ls.tagId;
            _livestockLabel =
                tag != null ? '${ls.name ?? 'Tanpa Nama'} (Tag: $tag)' : ls.name ?? '-';
          });
        }
      } catch (_) {
        if (mounted) setState(() => _livestockLabel = 'ID: ${item.livestockId}');
      }
    }

    if (item.conditionType != null && item.conditionType!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _conditionTypeLabel =
              item.conditionType!['label'] as String? ?? '-';
        });
      }
    } else {
      try {
        final repo = ref.read(farmRepositoryProvider);
        final ct = await repo.getConditionTypeDetail(item.conditionTypeId);
        if (mounted) {
          setState(() {
            _conditionTypeLabel = ct['label'] as String? ?? '-';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _conditionTypeLabel = 'ID: ${item.conditionTypeId}');
        }
      }
    }
  }

  // ==========================================
  // DELETE
  // ==========================================

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Catatan?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan kondisi ini? Tindakan ini tidak dapat dibatalkan.',
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
          .read(conditionHistoryRepositoryProvider)
          .deleteConditionHistory(_current.id);

      if (mounted) {
        ref
            .read(conditionHistoryListProvider.notifier)
            .fetchHistories(isRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil dihapus'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus catatan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final item = _current;
    final color = _conditionColor;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Detail Catatan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.scaffoldBackground,
        actions: [
          // Tombol Edit
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            color: const Color(0xFFF59E0B),
            onPressed: () async {
              final updated =
                  await context.push<ConditionHistoryModel?>(
                '/condition-history/form',
                extra: _current,
              );
              if (updated != null) {
                setState(() => _current = updated);
                _loadLabels();
              }
            },
          ),
          // Tombol Hapus
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.red,
            onPressed: _isDeleting ? null : _showDeleteDialog,
          ),
        ],
      ),
      body: _isDeleting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: Color(0xFFF59E0B)),
                  const SizedBox(height: 16),
                  Text(
                    'Menghapus catatan...',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- HERO CARD ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
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
                        // Ikon Kondisi
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _conditionIcon,
                            size: 38,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Label Kondisi
                        Text(
                          _conditionTypeLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // Tanggal
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                .format(item.recordDate),
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

                  // --- KARTU INFO ---
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
                              Icons.info_outline_rounded,
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Informasi Catatan',
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
                          Icons.pets_rounded,
                          'Ternak',
                          _livestockLabel,
                        ),
                        _buildInfoRow(
                          Icons.health_and_safety_outlined,
                          'Jenis Kondisi',
                          _conditionTypeLabel,
                        ),
                        _buildInfoRow(
                          Icons.calendar_today_rounded,
                          'Tanggal Kejadian',
                          DateFormat('dd MMMM yyyy', 'id_ID')
                              .format(item.recordDate),
                        ),
                        _buildInfoRow(
                          Icons.access_time_rounded,
                          'Dicatat Pada',
                          DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                              .format(item.createdAt.toLocal()),
                        ),
                      ],
                    ),
                  ),

                  // --- KARTU CATATAN (jika ada) ---
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
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
                                Icons.notes_rounded,
                                color: color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Catatan Tambahan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              item.notes!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
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
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
