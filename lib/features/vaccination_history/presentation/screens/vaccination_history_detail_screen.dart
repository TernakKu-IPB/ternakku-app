import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/vaccination_history/data/repositories/vaccination_history_repository.dart';
import 'package:ternakku_app/features/vaccination_history/domain/models/vaccination_history_model.dart';
import 'package:ternakku_app/features/vaccination_history/presentation/providers/vaccination_history_list_provider.dart';
import 'package:ternakku_app/features/livestock/data/repositories/livestock_repository.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';

class VaccinationHistoryDetailScreen extends ConsumerStatefulWidget {
  final VaccinationHistoryModel history;

  const VaccinationHistoryDetailScreen({super.key, required this.history});

  @override
  ConsumerState<VaccinationHistoryDetailScreen> createState() =>
      _VaccinationHistoryDetailScreenState();
}

class _VaccinationHistoryDetailScreenState
    extends ConsumerState<VaccinationHistoryDetailScreen> {
  bool _isDeleting = false;
  bool _isMarkingVaccinated = false;
  late VaccinationHistoryModel _current;

  // Labels yang di-fetch dari API
  String _livestockLabel = '-';
  String _vaccineLabel = '-';

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

  int get _daysUntilVaccination {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final vaccinationDate = DateTime(
      _current.vaccinationDate.year,
      _current.vaccinationDate.month,
      _current.vaccinationDate.day,
    );

    return vaccinationDate.difference(today).inDays;
  }

  bool get _isToday =>
      !_current.isVaccinated && _daysUntilVaccination == 0;

  bool get _isOverdue =>
      !_current.isVaccinated && _daysUntilVaccination < 0;

  bool get _isUpcoming =>
      !_current.isVaccinated &&
      _daysUntilVaccination > 0 &&
      _daysUntilVaccination <= 7;

  Color get _statusColor {
    if (_current.isVaccinated) return const Color(0xFF22C55E); // Hijau
    if (_isToday) return const Color(0xFFF97316); // Oranye
    if (_isOverdue) return const Color(0xFFEF4444); // Merah
    if (_isUpcoming) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF3B82F6); // Biru
  }

  IconData get _statusIcon {
    if (_current.isVaccinated) return Icons.check_circle_rounded;
    if (_isToday) return Icons.today_rounded;
    if (_isOverdue) return Icons.warning_amber_rounded;
    if (_isUpcoming) return Icons.notification_important_rounded;
    return Icons.schedule_rounded;
  }

  String get _statusLabel {
    if (_current.isVaccinated) return 'Sudah Divaksinasi';
    if (_isToday) return 'Hari Ini';
    if (_isOverdue) return 'Terlambat';
    if (_isUpcoming) return 'Segera Divaksinasi';
    return 'Terjadwal';
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
            _livestockLabel = tag != null
                ? '${ls.name ?? 'Tanpa Nama'} (Tag: $tag)'
                : ls.name ?? '-';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _livestockLabel = 'ID: ${item.livestockId}');
        }
      }
    }

    if (item.vaccine != null && item.vaccine!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _vaccineLabel = item.vaccine!['name'] as String? ?? '-';
        });
      }
    } else {
      try {
        final repo = ref.read(farmRepositoryProvider);
        final v = await repo.getVaccineDetail(item.vaccineId);
        if (mounted) {
          setState(() {
            _vaccineLabel = v['name'] as String? ?? '-';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _vaccineLabel = 'ID: ${item.vaccineId}');
        }
      }
    }
  }

  // ==========================================
  // MARK AS VACCINATED
  // ==========================================

  Future<void> _markAsVaccinated() async {
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
          'Tandai vaksinasi ini sebagai selesai? Tindakan ini akan memperbarui status ternak.',
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

    if (confirm != true || !mounted) return;

    setState(() => _isMarkingVaccinated = true);
    try {
      final updated = await ref
          .read(vaccinationHistoryRepositoryProvider)
          .markAsVaccinated(_current.id);

      if (mounted) {
        setState(() => _current = updated);
        ref
            .read(vaccinationHistoryListProvider.notifier)
            .markAsVaccinated(_current.id);
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
      if (mounted) setState(() => _isMarkingVaccinated = false);
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Rekam Medis?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus rekam medis ini? Tindakan ini tidak dapat dibatalkan.',
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
          .read(vaccinationHistoryRepositoryProvider)
          .deleteVaccinationHistory(_current.id);

      if (mounted) {
        ref
            .read(vaccinationHistoryListProvider.notifier)
            .fetchHistories(isRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rekam medis berhasil dihapus'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus rekam medis'),
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
    final color = _statusColor;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Detail Rekam Medis',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.scaffoldBackground,
        actions: [
          // Tombol Edit
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            color: const Color(0xFFEF4444),
            onPressed: () async {
              final updated =
                  await context.push<VaccinationHistoryModel?>(
                '/vaccination-history/form',
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
                      color: Color(0xFFEF4444)),
                  const SizedBox(height: 16),
                  Text(
                    'Menghapus rekam medis...',
                    style:
                        GoogleFonts.poppins(color: Colors.grey.shade600),
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
                        // Ikon Status
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _statusIcon,
                            size: 38,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Label Status
                        Text(
                          _statusLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // Nama Vaksin
                        Text(
                          _vaccineLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

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
                                .format(item.vaccinationDate),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        // Tombol Tandai Vaksin (jika belum divaksinasi)
                        if (!item.isVaccinated) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isMarkingVaccinated
                                ? null
                                : _markAsVaccinated,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: color,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: _isMarkingVaccinated
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              'Tandai Sudah Divaksinasi',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
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
                              'Informasi Rekam Medis',
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
                          Icons.vaccines_rounded,
                          'Jenis Vaksin',
                          _vaccineLabel,
                        ),
                        _buildInfoRow(
                          Icons.calendar_today_rounded,
                          'Tanggal Vaksinasi',
                          DateFormat('dd MMMM yyyy', 'id_ID')
                              .format(item.vaccinationDate),
                        ),
                        if (item.batchNumber != null &&
                            item.batchNumber!.isNotEmpty)
                          _buildInfoRow(
                            Icons.qr_code_rounded,
                            'No. Batch',
                            item.batchNumber!,
                          ),
                        _buildInfoRow(
                          Icons.circle_outlined,
                          'Status',
                          _statusLabel,
                          valueColor: color,
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
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
                color: valueColor ?? AppTheme.textPrimary,
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
