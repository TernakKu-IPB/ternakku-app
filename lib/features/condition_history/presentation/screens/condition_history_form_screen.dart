import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/condition_history/domain/models/condition_history_model.dart';
import 'package:ternakku_app/features/condition_history/data/repositories/condition_history_repository.dart';
import 'package:ternakku_app/features/condition_history/presentation/providers/condition_history_list_provider.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import 'package:ternakku_app/features/livestock/data/repositories/livestock_repository.dart';
import 'package:ternakku_app/features/livestock/domain/models/livestock_model.dart';

// =============================================================================
// FORM SCREEN
// =============================================================================
class ConditionHistoryFormScreen extends ConsumerStatefulWidget {
  final ConditionHistoryModel? history; // null = Tambah, ada = Edit

  const ConditionHistoryFormScreen({super.key, this.history});

  @override
  ConsumerState<ConditionHistoryFormScreen> createState() =>
      _ConditionHistoryFormScreenState();
}

class _ConditionHistoryFormScreenState
    extends ConsumerState<ConditionHistoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  // State Values
  int? _selectedLivestockId;
  String? _selectedLivestockLabel;

  int? _selectedConditionTypeId;
  String? _selectedConditionTypeLabel;

  DateTime _selectedRecordDate = DateTime.now();

  bool _isLoading = false;
  Map<String, String> _serverErrors = {};

  bool get _isEdit => widget.history != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final item = widget.history!;
      _notesController.text = item.notes ?? '';
      _selectedRecordDate = item.recordDate;

      // Set data dari relasi jika sudah ada
      _selectedLivestockId = item.livestockId;
      if (item.livestock != null && item.livestock!.isNotEmpty) {
        final name = item.livestock!['name'] as String? ?? 'Tanpa Nama';
        final tag = item.livestock!['tagId'] as String?;
        _selectedLivestockLabel =
            tag != null ? '$name ($tag)' : name;
      } else {
        _selectedLivestockLabel = 'Memuat data...';
      }

      _selectedConditionTypeId = item.conditionTypeId;
      if (item.conditionType != null && item.conditionType!.isNotEmpty) {
        _selectedConditionTypeLabel =
            item.conditionType!['label'] as String? ?? 'Memuat data...';
      } else {
        _selectedConditionTypeLabel = 'Memuat data...';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReferenceLabels();
      });
    }
  }

  @override
  void dispose() {
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

    // Load label tipe kondisi
    try {
      final repo = ref.read(farmRepositoryProvider);
      final condType = await repo.getConditionTypeDetail(item.conditionTypeId);
      if (mounted) {
        setState(() {
          _selectedConditionTypeLabel = condType['label'] as String?;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _selectedConditionTypeLabel = 'ID: ${item.conditionTypeId}');
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

  Future<List<Map<String, dynamic>>> _searchConditionTypes(String q) async {
    final repo = ref.read(farmRepositoryProvider);
    return await repo.getConditionTypes(query: q);
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
        hintText: 'Cari nama atau tag ternak...',
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

  void _openConditionTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ModalSearchBottomSheet<Map<String, dynamic>>(
        title: 'Pilih Jenis Kondisi',
        hintText: 'Cari jenis kondisi...',
        onSearch: _searchConditionTypes,
        allowNull: false,
        itemBuilder: (item) => Text(
          '${item['label']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onSelected: (item) {
          if (item != null) {
            setState(() {
              _selectedConditionTypeId = item['id'];
              _selectedConditionTypeLabel = item['label'];
              _serverErrors.remove('conditionTypeId');
            });
          }
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedRecordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF59E0B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedRecordDate = picked);
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

    if (_selectedConditionTypeId == null) {
      const msg = 'Pilih jenis kondisi terlebih dahulu';
      setState(() => _serverErrors['conditionTypeId'] = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(conditionHistoryRepositoryProvider);
      ConditionHistoryModel? resultData;

      final payload = {
        'livestockId': _selectedLivestockId,
        'conditionTypeId': _selectedConditionTypeId,
        'recordDate':
            DateFormat('yyyy-MM-dd').format(_selectedRecordDate),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (_isEdit) {
        resultData = await repo.updateConditionHistory(
            widget.history!.id, payload);
      } else {
        resultData = await repo.createConditionHistory(payload);
      }

      if (!mounted) return;

      ref
          .read(conditionHistoryListProvider.notifier)
          .fetchHistories(isRefresh: true);

      context.pop(resultData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Catatan berhasil diperbarui'
                : 'Catatan baru berhasil ditambahkan',
          ),
          backgroundColor: const Color(0xFFF59E0B),
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
          _isEdit ? 'Edit Catatan' : 'Tambah Catatan',
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
                          floatingLabelBehavior:
                              FloatingLabelBehavior.always,
                          errorText: _serverErrors['livestockId'],
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        isEmpty: _selectedLivestockId == null,
                        child: Text(
                          _selectedLivestockLabel ??
                              'Pilih ternak yang akan dicatat...',
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

                // --- KARTU 2: DETAIL KONDISI ---
                _buildSectionCard(
                  title: 'Detail Kondisi',
                  icon: Icons.health_and_safety_outlined,
                  children: [
                    // Pilih Jenis Kondisi
                    InkWell(
                      onTap: _openConditionTypePicker,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Jenis Kondisi *',
                          floatingLabelBehavior:
                              FloatingLabelBehavior.always,
                          errorText: _serverErrors['conditionTypeId'],
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        isEmpty: _selectedConditionTypeId == null,
                        child: Text(
                          _selectedConditionTypeLabel ??
                              'Pilih jenis kondisi...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _selectedConditionTypeId == null
                                ? Colors.grey.shade600
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Kejadian
                    GestureDetector(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Kejadian *',
                          floatingLabelBehavior:
                              FloatingLabelBehavior.always,
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        isEmpty: false,
                        child: Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                              .format(_selectedRecordDate),
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                            'Tambahkan keterangan tambahan, misal: ternak tampak lemas, tidak mau makan...',
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
                    backgroundColor: const Color(0xFFF59E0B),
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
                          _isEdit ? 'Perbarui Catatan' : 'Simpan Catatan',
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
              Icon(icon, color: const Color(0xFFF59E0B), size: 22),
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
                  const Icon(Icons.search, color: Color(0xFFF59E0B)),
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
                    color: Color(0xFFF59E0B), width: 2),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF59E0B),
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
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFF59E0B),
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
