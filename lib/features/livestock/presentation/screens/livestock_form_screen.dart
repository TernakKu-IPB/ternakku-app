import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import '../../domain/models/livestock_model.dart';
import '../../data/repositories/livestock_repository.dart';
import '../providers/livestock_list_provider.dart'; 

class LivestockFormScreen extends ConsumerStatefulWidget {
  final LivestockModel? livestock; // Jika null = Tambah, Jika ada = Edit

  const LivestockFormScreen({super.key, this.livestock});

  @override
  ConsumerState<LivestockFormScreen> createState() => _LivestockFormScreenState();
}

class _LivestockFormScreenState extends ConsumerState<LivestockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _tagIdController = TextEditingController();
  final _nameController = TextEditingController();
  
  // State Values - Identitas & Status
  String _selectedGender = 'female';
  DateTime? _selectedBirthDate;
  String _selectedStatus = 'active';
  
  // State Values - Relasi (Dengan Label untuk Mencegah Overflow)
  int? _selectedAnimalTypeId;
  String? _selectedAnimalTypeLabel;

  int? _selectedFatherId;
  String? _selectedFatherLabel;

  int? _selectedMotherId;
  String? _selectedMotherLabel;

  bool _isLoading = false;
  Map<String, String> _serverErrors = {};

  bool get _isEdit => widget.livestock != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final item = widget.livestock!;
      _tagIdController.text = item.tagId ?? '';
      _nameController.text = item.name ?? '';
      _selectedGender = item.gender;
      if (item.birthDate != null) {
        _selectedBirthDate = item.birthDate;
      }
      _selectedStatus = item.status;

      // Set placeholder "Memuat..." sambil menunggu API
      _selectedAnimalTypeId = item.animalTypeId;
      _selectedAnimalTypeLabel = 'Memuat data ...';
      
      if (item.fatherId != null) {
        _selectedFatherId = item.fatherId;
        _selectedFatherLabel = 'Memuat data ...';
      }
      
      if (item.motherId != null) {
        _selectedMotherId = item.motherId;
        _selectedMotherLabel = 'Memuat data ...';
      }

      // Jalankan fetch label di background setelah UI dirender
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReferenceLabels();
      });
    }
  }

  // ==========================================
  // FETCH LABEL ASLI (UNTUK MODE EDIT)
  // ==========================================
  Future<void> _loadReferenceLabels() async {
    final item = widget.livestock!;
    final livestockRepo = ref.read(livestockRepositoryProvider);
    final farmRepo = ref.read(farmRepositoryProvider);

    // 1. Ambil nama Jenis Ternak berdasarkan ID
    try {
      final animalType = await farmRepo.getAnimalTypeDetail(item.animalTypeId);
      
      if (mounted) {
        setState(() {
          // Ambil 'label' dari response backend
          _selectedAnimalTypeLabel = animalType['label'];
        });
      }
    } catch (e) {
      // Fallback jika API gagal
      if (mounted) setState(() => _selectedAnimalTypeLabel = 'ID: ${item.animalTypeId}');
    }

    // 2. Ambil data Pejantan (Bapak)
    if (item.fatherId != null) {
      try {
        final father = await livestockRepo.getLivestockDetail(item.fatherId!);
        if (mounted) {
          setState(() {
            _selectedFatherLabel = [
              father.name ?? 'Tanpa Nama',
              father.tagId != null ? '(${father.tagId})' : null,
            ].whereType<String>().join(' ');
          });
        }
      } catch (e) {
        if (mounted) setState(() => _selectedFatherLabel = 'ID: ${item.fatherId}');
      }
    }

    // 3. Ambil data Induk (Ibu)
    if (item.motherId != null) {
      try {
        final mother = await livestockRepo.getLivestockDetail(item.motherId!);
        if (mounted) {
          setState(() {
            _selectedMotherLabel = [
              mother.name ?? 'Tanpa Nama',
              mother.tagId != null ? '(${mother.tagId})' : null,
            ].whereType<String>().join(' ');
          });
        }
      } catch (e) {
        if (mounted) setState(() => _selectedMotherLabel = 'ID: ${item.motherId}');
      }
    }
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNGSI PENCARIAN API UNTUK BOTTOM SHEET
  // ==========================================
  Future<List<Map<String, dynamic>>> _searchAnimalTypes(String q) async {
    final repo = ref.read(farmRepositoryProvider);
    return await repo.getAnimalTypes(query: q);
  }

  Future<List<LivestockModel>> _searchFathers(String q) async {
    final repo = ref.read(livestockRepositoryProvider);
    final results = await repo.getLivestocks(limit: 20, status: 'active', gender: 'male', query: q);
    // Hapus dirinya sendiri dari daftar agar tidak menjadi bapaknya sendiri
    return results.where((e) => e.id != widget.livestock?.id).toList();
  }

  Future<List<LivestockModel>> _searchMothers(String q) async {
    final repo = ref.read(livestockRepositoryProvider);
    final results = await repo.getLivestocks(limit: 20, status: 'active', gender: 'female', query: q);
    // Hapus dirinya sendiri
    return results.where((e) => e.id != widget.livestock?.id).toList();
  }

  // ==========================================
  // PEMANGGIL BOTTOM SHEET
  // ==========================================
  void _openAnimalTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalSearchBottomSheet<Map<String, dynamic>>(
        title: 'Pilih Jenis Ternak',
        hintText: 'Cari jenis ternak ...',
        onSearch: _searchAnimalTypes,
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
              _selectedAnimalTypeId = item['id'];
              _selectedAnimalTypeLabel = item['label'];
              // Hilangkan error jika sebelumnya merah
              _serverErrors.remove('animalTypeId');
            });
          }
        },
      ),
    );
  }

  void _openFatherPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalSearchBottomSheet<LivestockModel>(
        title: 'Pilih Pejantan (Bapak)',
        hintText: 'Cari pejantan dari ternak ini ...',
        onSearch: _searchFathers,
        allowNull: true,
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
          setState(() {
            _selectedFatherId = item?.id;
            _selectedFatherLabel = item == null ? null : [
              item.name ?? 'Tanpa Nama',
              item.tagId != null ? '(${item.tagId})' : null,
            ].whereType<String>().join(' ');
            _serverErrors.remove('fatherId');
          });
        },
      ),
    );
  }

  void _openMotherPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalSearchBottomSheet<LivestockModel>(
        title: 'Pilih Induk (Ibu)',
        hintText: 'Cari induk dari ternak ini ...',
        onSearch: _searchMothers,
        allowNull: true,
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
          setState(() {
            _selectedMotherId = item?.id;
            _selectedMotherLabel = item == null ? null : [
              item.name ?? 'Tanpa Nama',
              item.tagId != null ? '(${item.tagId})' : null,
            ].whereType<String>().join(' ');
            _serverErrors.remove('motherId');
          });
        },
      ),
    );
  }

  // ==========================================
  // AKSI SUBMIT UTAMA
  // ==========================================
  Future<void> _submit() async {
    setState(() => _serverErrors = {});

    final tag = _tagIdController.text.trim();
    final name = _nameController.text.trim();
    
    if (tag.isEmpty && name.isEmpty) {
      const message = 'Setidaknya tag ID atau nama ternak harus diisi';
      setState(() {
        _serverErrors['tagId'] = message;
        _serverErrors['name'] = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimalTypeId == null) {
      const message = 'Pilih jenis ternak terlebih dahulu';
      setState(() => _serverErrors['animalTypeId'] = message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(livestockRepositoryProvider);
      LivestockModel? resultData;
      
      final payload = {
        'tagId': tag,
        'name': name,
        'animalTypeId': _selectedAnimalTypeId,
        'gender': _selectedGender,
        'birthDate': _selectedBirthDate == null ? null : DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
        'status': _selectedStatus,
        'fatherId': _selectedFatherId,
        'motherId': _selectedMotherId,
      };

      if (_isEdit) {
        resultData = await repo.updateLivestock(widget.livestock!.id, payload);
      } else {
        resultData = await repo.createLivestock(payload);
      }

      if (!mounted) return;

      ref.read(livestockListProvider.notifier).fetchLivestocks(isRefresh: true);
      context.pop(resultData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Data berhasil diperbarui' : 'Ternak baru berhasil ditambahkan'),
          backgroundColor: AppTheme.secondaryColor,
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Ternak' : 'Tambah Ternak', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
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
                // --- KARTU 1: IDENTITAS UTAMA ---
                _buildSectionCard(
                  title: 'Identitas Utama',
                  icon: Icons.badge_outlined,
                  children: [
                    TextFormField(
                      controller: _tagIdController,
                      decoration: InputDecoration(
                        labelText: 'Tag ID / Nomor Telinga',
                        hintText: 'Contoh: ET-000003',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: _serverErrors['tagId'],
                      ),
                      onChanged: (value) {
                        if (_serverErrors.containsKey('tagId')) {
                          setState(() => _serverErrors.remove('tagId'));
                          _formKey.currentState!.validate();
                        }
                        if (_serverErrors.containsKey('name')) {
                          setState(() => _serverErrors.remove('name'));
                          _formKey.currentState!.validate();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Ternak',
                        hintText: 'Contoh: Limookid',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText: _serverErrors['name'],
                      ),
                      onChanged: (value) {
                        if (_serverErrors.containsKey('name')) {
                          setState(() => _serverErrors.remove('name'));
                          _formKey.currentState!.validate();
                        }
                        if (_serverErrors.containsKey('tagId')) {
                          setState(() => _serverErrors.remove('tagId'));
                          _formKey.currentState!.validate();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Dropdown Custom untuk Jenis Ternak (Anti Overflow & Searchable)
                    InkWell(
                      onTap: _openAnimalTypePicker,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Jenis Ternak *',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          errorText: _serverErrors['animalTypeId'],
                          suffixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                        ),
                        isEmpty: _selectedAnimalTypeId == null,
                        child: Text(
                          _selectedAnimalTypeLabel ?? 'Pilih jenis ternak ...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _selectedAnimalTypeId == null ? Colors.grey.shade600 : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- KARTU 2: FISIK & STATUS ---
                _buildSectionCard(
                  title: 'Fisik & Status',
                  icon: Icons.health_and_safety_outlined,
                  children: [
                    Text(
                      'Jenis Kelamin',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildGenderCard('Jantan', 'male', Icons.male, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildGenderCard('Betina', 'female', Icons.female, Colors.pink)),
                      ],
                    ),
                    if (_serverErrors['gender'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                        child: Text(_serverErrors['gender']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 16),
                    
                    // Tanggal Lahir
                    GestureDetector(
                      onTap: () => _selectDate(),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Lahir (Opsional)',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_selectedBirthDate != null)
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Hapus tanggal',
                                  onPressed: () {
                                    setState(() {
                                      _selectedBirthDate = null;
                                    });
                                  },
                                ),
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        isEmpty: _selectedBirthDate == null,
                        child: Text(
                          _selectedBirthDate == null ? 'Pilih Tanggal' : DateFormat('dd MMMM yyyy').format(_selectedBirthDate!),
                          style: GoogleFonts.poppins(
                            color: _selectedBirthDate == null ? Colors.grey.shade600 : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Status
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Status Ternak',
                        errorText: _serverErrors['status'],
                        iconColor: AppTheme.primaryColor,
                      ),
                      initialValue: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Aktif')),
                        DropdownMenuItem(value: 'sold', child: Text('Terjual')),
                        DropdownMenuItem(value: 'dead', child: Text('Mati')),
                      ],
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- KARTU 3: SILSILAH KELUARGA ---
                _buildSectionCard(
                  title: 'Silsilah Keluarga (Opsional)',
                  icon: Icons.account_tree_outlined,
                  children: [
                    InkWell(
                      onTap: _openFatherPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Pejantan (Bapak)',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          errorText: _serverErrors['fatherId'],
                          suffixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                        ),
                        isEmpty: _selectedFatherId == null,
                        child: Text(
                          _selectedFatherLabel ?? 'Tidak diketahui / Cari Bapak',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // ANTI OVERFLOW
                          style: GoogleFonts.poppins(
                            color: _selectedFatherId == null ? Colors.grey.shade600 : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _openMotherPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Induk (Ibu)',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          errorText: _serverErrors['motherId'],
                          suffixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                        ),
                        isEmpty: _selectedMotherId == null,
                        child: Text(
                          _selectedMotherLabel ?? 'Tidak diketahui / Cari Ibu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _selectedMotherId == null ? Colors.grey.shade600 : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Tombol Simpan
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isEdit ? 'Perbarui Data Ternak' : 'Simpan Data Ternak',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
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
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGenderCard(String label, String value, IconData icon, Color color) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET WIDGET BOTTOM SHEET PENCARIAN (REUSABLE)
// ============================================================================
class ModalSearchBottomSheet<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final Future<List<T>> Function(String query) onSearch;
  final Widget Function(T item) itemBuilder;
  final void Function(T? item) onSelected;
  final bool allowNull;

  const ModalSearchBottomSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.onSearch,
    required this.itemBuilder,
    required this.onSelected,
    this.allowNull = true,
  });

  @override
  State<ModalSearchBottomSheet<T>> createState() => _ModalSearchBottomSheetState<T>();
}

class _ModalSearchBottomSheetState<T> extends State<ModalSearchBottomSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<T> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _executeSearch(''); // Panggil pertama kali dengan query kosong
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
    } catch (e) {
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
        // Responsif terhadap keyboard agar tidak tertutup saat mengetik
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      height: MediaQuery.of(context).size.height * 0.75, // 75% tinggi layar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle & Title
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
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
          
          // Search Box
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
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
                    color: AppTheme.primaryColor, width: 2),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),

          // List Hasil Pencarian
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      // Opsi Kosong (Jika diizinkan misal untuk hapus Silsilah)
                      if (widget.allowNull)
                        ListTile(
                          leading: const Icon(Icons.do_not_disturb_alt, color: Colors.grey),
                          title: Text('Kosongkan', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
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
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: AppTheme.primaryColor, size: 20),
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