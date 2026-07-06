import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/vaccination_history/domain/models/vaccination_history_model.dart';
import 'package:ternakku_app/features/vaccination_history/data/repositories/vaccination_history_repository.dart';
import 'package:ternakku_app/features/vaccination_history/presentation/providers/vaccination_history_list_provider.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import 'package:ternakku_app/features/livestock/data/repositories/livestock_repository.dart';
import 'package:ternakku_app/features/livestock/domain/models/livestock_model.dart';

// =============================================================================
// FORM SCREEN
// =============================================================================
class VaccinationHistoryFormScreen extends ConsumerStatefulWidget {
  final VaccinationHistoryModel? history; // null = Tambah, ada = Edit

  const VaccinationHistoryFormScreen({super.key, this.history});

  @override
  ConsumerState<VaccinationHistoryFormScreen> createState() =>
      _VaccinationHistoryFormScreenState();
}

class _VaccinationHistoryFormScreenState
    extends ConsumerState<VaccinationHistoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // State Values
  int? _selectedLivestockId;
  String? _selectedLivestockLabel;

  int? _selectedVaccineId;
  String? _selectedVaccineLabel;

  DateTime _selectedVaccinationDate = DateTime.now();
  bool _isVaccinated = false;

  bool _isLoading = false;
  Map<String, String> _serverErrors = {};

  bool get _isEdit => widget.history != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final item = widget.history!;
      _batchNumberController.text = item.batchNumber ?? '';
      _notesController.text = item.notes ?? '';
      _selectedVaccinationDate = item.vaccinationDate;
      _isVaccinated = item.isVaccinated;

      // Set data dari relasi jika sudah ada
      _selectedLivestockId = item.livestockId;
      if (item.livestock != null && item.livestock!.isNotEmpty) {
        final name = item.livestock!['name'] as String? ?? 'Tanpa Nama';
        final tag = item.livestock!['tagId'] as String?;
        _selectedLivestockLabel = tag != null ? '$name ($tag)' : name;
      } else {
        _selectedLivestockLabel = 'Memuat data ...';
      }

      _selectedVaccineId = item.vaccineId;
      if (item.vaccine != null && item.vaccine!.isNotEmpty) {
        _selectedVaccineLabel = item.vaccine!['name'] as String? ?? 'Memuat data ...';
      } else {
        _selectedVaccineLabel = 'Memuat data ...';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReferenceLabels();
      });
    }
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ==========================================
  // FETCH LABELS UNTUK MODE EDIT
  // ==========================================
  Future<void> _loadReferenceLabels() async {
    final item = widget.history!;

    // Load label ternak
    try {
      final repo = ref.read(livestockRepositoryProvider);
      final livestock = await repo.getLivestockDetail(item.livestockId);
      if (mounted) {
        setState(() {
          final tag = livestock.tagId;
          _selectedLivestockLabel = tag != null
              ? '${livestock.name ?? 'Tanpa Nama'} ($tag)'
              : livestock.name ?? 'Tanpa Nama';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _selectedLivestockLabel = 'ID: ${item.livestockId}');
      }
    }

    // Load label vaksin
    try {
      final repo = ref.read(farmRepositoryProvider);
      final vaccine = await repo.getVaccineDetail(item.vaccineId);
      if (mounted) {
        setState(() {
          _selectedVaccineLabel = vaccine['name'] as String?;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _selectedVaccineLabel = 'ID: ${item.vaccineId}');
      }
    }
  }

  // ==========================================
  // SEARCH FUNCTIONS UNTUK BOTTOM SHEETS
  // ==========================================
  Future<List<LivestockModel>> _searchLivestocks(String q) async {
    final repo = ref.read(livestockRepositoryProvider);
    return await repo.getLivestocks(limit: 20, status: 'active', query: q);
  }

  Future<List<Map<String, dynamic>>> _searchVaccines(String q) async {
    final repo = ref.read(farmRepositoryProvider);
    return await repo.getVaccines(query: q);
  }

  // ==========================================
  // PICKERS (BOTTOM SHEETS)
  // ==========================================
  void _openLivestockPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalSearchBottomSheet<LivestockModel>(
        title: 'Pilih Ternak',
        hintText: 'Cari nama atau tag ternak ...',
        onSearch: _searchLivestocks,
        allowNull: false,
        itemBuilder: (item) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name ?? 'Tanpa Nama',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (item.tagId != null)
              Text(
                'Tag: ${item.tagId}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
        onSelected: (item) {
          if (item != null) {
            setState(() {
              _selectedLivestockId = item.id;
              final tag = item.tagId;
              _selectedLivestockLabel = tag != null
                  ? '${item.name ?? 'Tanpa Nama'} ($tag)'
                  : item.name ?? 'Tanpa Nama';
              _serverErrors.remove('livestockId');
            });
          }
        },
      ),
    );
  }

  void _openVaccinePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ModalSearchBottomSheet<Map<String, dynamic>>(
        title: 'Pilih Jenis Vaksin',
        hintText: 'Cari nama vaksin ...',
        onSearch: _searchVaccines,
        allowNull: false,
        itemBuilder: (item) => Text(
          '${item['name']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onSelected: (item) {
          if (item != null) {
            setState(() {
              _selectedVaccineId = item['id'];
              _selectedVaccineLabel = item['name'];
              _serverErrors.remove('vaccineId');
            });
          }
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedVaccinationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEF4444),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedVaccinationDate = picked);
      _serverErrors.remove('vaccinationDate');
    }
  }

  // ==========================================
  // SUBMIT
  // ==========================================
  Future<void> _submit() async {
    setState(() => _serverErrors = {});

    if (_selectedLivestockId == null) {
      const msg = 'Pilih ternak terlebih dahulu';
      setState(() => _serverErrors['livestockId'] = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedVaccineId == null) {
      const msg = 'Pilih jenis vaksin terlebih dahulu';
      setState(() => _serverErrors['vaccineId'] = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isVaccinated && _selectedVaccinationDate.isAfter(DateTime.now())) {
      const msg = 'Maksimal pilih hari ini jika ternak sudah divaksin';
      setState(() {
        _serverErrors['vaccinationDate'] = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(vaccinationHistoryRepositoryProvider);
      VaccinationHistoryModel? resultData;

      final payload = {
        'livestockId': _selectedLivestockId,
        'vaccineId': _selectedVaccineId,
        'vaccinationDate':
            DateFormat('yyyy-MM-dd').format(_selectedVaccinationDate),
        'isVaccinated': _isVaccinated,
        if (_batchNumberController.text.trim().isNotEmpty)
          'batchNumber': _batchNumberController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      if (_isEdit) {
        resultData = await repo.updateVaccinationHistory(
            widget.history!.id, payload);
      } else {
        resultData = await repo.createVaccinationHistory(payload);
      }

      if (!mounted) return;

      ref
          .read(vaccinationHistoryListProvider.notifier)
          .fetchHistories(isRefresh: true);

      context.pop(resultData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Rekam medis berhasil diperbarui'
                : 'Jadwal vaksinasi berhasil ditambahkan',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } on ApiException catch (e) {
      if (e.fieldErrors != null && e.fieldErrors!.isNotEmpty) {
        setState(() => _serverErrors = e.fieldErrors!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Rekam Medis' : 'Jadwalkan Vaksinasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.scaffoldBackground,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- KARTU 1: PILIH TERNAK ---
                _buildSectionCard(
                  title: 'Data Ternak',
                  icon: Icons.pets_outlined,
                  children: [
                    InkWell(
                      onTap: _openLivestockPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ternak *',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          errorText: _serverErrors['livestockId'],
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        isEmpty: _selectedLivestockId == null,
                        child: Text(
                          _selectedLivestockLabel ??
                              'Pilih ternak yang akan divaksinasi ...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _selectedLivestockId == null
                                ? Colors.grey.shade600
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- KARTU 2: DETAIL VAKSINASI ---
                _buildSectionCard(
                  title: 'Detail Vaksinasi',
                  icon: Icons.vaccines_outlined,
                  children: [
                    // Pilih Jenis Vaksin
                    InkWell(
                      onTap: _openVaccinePicker,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Jenis Vaksin *',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          errorText: _serverErrors['vaccineId'],
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        isEmpty: _selectedVaccineId == null,
                        child: Text(
                          _selectedVaccineLabel ??
                              'Pilih jenis vaksin ...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _selectedVaccineId == null
                                ? Colors.grey.shade600
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Vaksinasi
                    GestureDetector(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Vaksinasi *',
                          errorText: _serverErrors['vaccinationDate'],
                          errorMaxLines: 2,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        isEmpty: false,
                        child: Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                              .format(_selectedVaccinationDate),
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // No. Batch Vaksin
                    TextFormField(
                      controller: _batchNumberController,
                      decoration: InputDecoration(
                        labelText: 'No. Batch Vaksin (Opsional)',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: 'Contoh: BT-2024-001',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        errorText: _serverErrors['batchNumber'],
                        prefixIcon: const Icon(
                          Icons.qr_code_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      onChanged: (_) {
                        if (_serverErrors.containsKey('batchNumber')) {
                          setState(() => _serverErrors.remove('batchNumber'));
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Toggle isVaccinated
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isVaccinated
                            ? const Color(0xFF22C55E).withValues(alpha: 0.06)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isVaccinated
                              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isVaccinated
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            color: _isVaccinated
                                ? const Color(0xFF22C55E)
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sudah Divaksinasi',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  _isVaccinated
                                      ? 'Vaksinasi telah dilaksanakan'
                                      : 'Masih dijadwalkan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isVaccinated,
                            onChanged: (val) => {
                              setState(() { 
                                _isVaccinated = val;
                                _serverErrors.remove('vaccinationDate');
                              }),
                            },
                            activeThumbColor: const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- KARTU 3: CATATAN TAMBAHAN ---
                _buildSectionCard(
                  title: 'Catatan (Opsional)',
                  icon: Icons.notes_rounded,
                  children: [
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Tambahkan keterangan tambahan, misal: reaksi vaksin, kondisi ternak saat divaksin ...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        errorText: _serverErrors['notes'],
                        alignLabelWithHint: true,
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      onChanged: (_) {
                        if (_serverErrors.containsKey('notes')) {
                          setState(() => _serverErrors.remove('notes'));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Tombol Simpan
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEdit
                              ? 'Perbarui Rekam Medis'
                              : 'Simpan Jadwal Vaksinasi',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
              Icon(icon, color: const Color(0xFFEF4444), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// =============================================================================
// REUSABLE MODAL SEARCH BOTTOM SHEET (LOCAL)
// =============================================================================
class _ModalSearchBottomSheet<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final Future<List<T>> Function(String query) onSearch;
  final Widget Function(T item) itemBuilder;
  final void Function(T? item) onSelected;
  final bool allowNull;

  const _ModalSearchBottomSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.onSearch,
    required this.itemBuilder,
    required this.onSelected,
    this.allowNull = true,
  });

  @override
  State<_ModalSearchBottomSheet<T>> createState() =>
      _ModalSearchBottomSheetState<T>();
}

class _ModalSearchBottomSheetState<T>
    extends State<_ModalSearchBottomSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<T> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _executeSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.onSearch(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFFEF4444)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _executeSearch('');
                      },
                    )
                  : null,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFEF4444), width: 2),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEF4444),
                    ),
                  )
                : ListView(
                    children: [
                      if (widget.allowNull)
                        ListTile(
                          leading: const Icon(
                            Icons.do_not_disturb_alt,
                            color: Colors.grey,
                          ),
                          title: Text(
                            'Kosongkan',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600),
                          ),
                          onTap: () {
                            widget.onSelected(null);
                            Navigator.pop(context);
                          },
                        ),
                      if (_results.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Data tidak ditemukan',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._results.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                            ),
                            title: widget.itemBuilder(item),
                            onTap: () {
                              widget.onSelected(item);
                              Navigator.pop(context);
                            },
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
