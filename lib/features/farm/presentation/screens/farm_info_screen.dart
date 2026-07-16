import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/farm/data/repositories/farm_repository.dart';
import 'package:ternakku_app/features/dashboard_provider.dart';
import '../providers/farm_info_providers.dart';

class FarmInfoScreen extends ConsumerStatefulWidget {
  const FarmInfoScreen({super.key});

  @override
  ConsumerState<FarmInfoScreen> createState() => _FarmInfoScreenState();
}

class _FarmInfoScreenState extends ConsumerState<FarmInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile Form Controllers
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // Set Profile fields once loaded
  void _initProfileFields(Map<String, dynamic> data) {
    if (_nameController.text.isEmpty && _addressController.text.isEmpty) {
      _nameController.text = data['name'] ?? '';
      _addressController.text = data['address'] ?? '';
      _descController.text = data['description'] ?? '';
      _latController.text = data['latitude']?.toString() ?? '';
      _lngController.text = data['longitude']?.toString() ?? '';
    }
  }

  // --- ACTIONS ---

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    try {
      final repo = ref.read(farmRepositoryProvider);
      await repo.createOrUpdateMyFarm(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: double.tryParse(_latController.text),
        longitude: double.tryParse(_lngController.text),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );

      // Refresh providers
      ref.invalidate(farmInfoDetailsProvider);
      ref.read(dashboardProvider.notifier).loadDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil peternakan berhasil diperbarui ✓'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil peternakan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _handleSelectLocation() {
    // Nanti di sini kita bisa integrasikan paket koordinat atau mock data terlebih dahulu
    setState(() {
      _latController.text = "-6.5599125";
      _lngController.text = "106.7255118";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokasi berhasil disematkan (Mock Data)')),
    );
  }

  // --- ANIMAL TYPE DIALOGS ---

  void _showAnimalTypeDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final labelController = TextEditingController(text: item?['label'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Jenis Ternak' : 'Tambah Jenis Ternak',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: labelController,
            decoration: const InputDecoration(
              labelText: 'Nama Jenis Ternak',
              hintText: 'Contoh: Kuda Poni',
            ),
            validator: (val) { 
              if (val != null) {
                if (val.length < 2) return 'Minimal 2 karakter';
                if (val.length > 100) return 'Maksimal 100 karakter';
                return null;
              }
              return 'Minimal 2 karakter';
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              try {
                final repo = ref.read(farmRepositoryProvider);
                final label = labelController.text.trim();
                final code = label.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
                if (isEdit) {
                  await repo.updateCustomAnimalType(item['id'], code, label);
                } else {
                  await repo.addCustomAnimalType(code, label,);
                }
                if (!mounted) return;
                ref.invalidate(farmInfoAnimalTypesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit
                        ? 'Jenis ternak diperbarui ✓'
                        : 'Jenis ternak ditambahkan ✓'),
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                );
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menyimpan jenis ternak'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAnimalTypeDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Jenis Ternak?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item['label']}"?',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(farmRepositoryProvider);
                await repo.deleteCustomAnimalType(item['id']);
                if (!mounted) return;
                ref.invalidate(farmInfoAnimalTypesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jenis ternak berhasil dihapus ✓'),
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                );
              } catch (e) {
                late String message;
                if (e is ApiException && e.statusCode == 422) {
                  message = e.message;
                } else {
                  message = 'Gagal menghapus jenis ternak';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- CONDITION TYPE DIALOGS ---

  void _showConditionTypeDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final labelController = TextEditingController(text: item?['label'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Jenis Kondisi' : 'Tambah Jenis Kondisi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: labelController,
            decoration: const InputDecoration(
              labelText: 'Nama Kondisi',
              hintText: 'Contoh: Masa Pemulihan',
            ),
            validator: (val) { 
              if (val != null) {
                if (val.length < 2) return 'Minimal 2 karakter';
                if (val.length > 100) return 'Maksimal 100 karakter';
                return null;
              }
              return 'Minimal 2 karakter';
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              try {
                final repo = ref.read(farmRepositoryProvider);
                final label = labelController.text.trim();
                final code = label.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
                if (isEdit) {
                  await repo.updateCustomConditionType(item['id'], code, label);
                } else {
                  await repo.addCustomConditionType(code, label);
                }
                ref.invalidate(farmInfoConditionTypesProvider);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit
                        ? 'Jenis kondisi diperbarui ✓'
                        : 'Jenis kondisi ditambahkan ✓'),
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                );
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menyimpan jenis kondisi'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConditionTypeDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Jenis Kondisi?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item['label']}"?',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(farmRepositoryProvider);
                await repo.deleteCustomConditionType(item['id']);
                if (!mounted) return;
                ref.invalidate(farmInfoConditionTypesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jenis kondisi berhasil dihapus ✓'),
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                );
              } catch (e) {
                late String message;
                if (e is ApiException && e.statusCode == 422) {
                  message = e.message;
                } else {
                  message = 'Gagal menghapus jenis kondisi';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- VACCINE DIALOGS ---

  void _showVaccineDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Jenis Vaksin' : 'Tambah Jenis Vaksin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Vaksin',
              hintText: 'Contoh: Vaksin Brucellosis',
            ),
            validator: (val) { 
              if (val != null) {
                if (val.length < 2) return 'Minimal 2 karakter';
                if (val.length > 100) return 'Maksimal 100 karakter';
                return null;
              }
              return 'Minimal 2 karakter';
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              try {
                final repo = ref.read(farmRepositoryProvider);
                final name = nameController.text.trim();
                final code = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
                if (isEdit) {
                  await repo.updateCustomVaccine(item['id'], code, name);
                } else {
                  await repo.addCustomVaccine(code, name);
                }
                if (!mounted) return;
                ref.invalidate(farmInfoVaccinesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit
                        ? 'Jenis vaksin diperbarui ✓'
                        : 'Jenis vaksin ditambahkan ✓'),
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                );
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menyimpan jenis vaksin'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteVaccineDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Jenis Vaksin?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item['name']}"?',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(farmRepositoryProvider);
                await repo.deleteCustomVaccine(item['id']);
                if (!mounted) return;
                ref.invalidate(farmInfoVaccinesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jenis vaksin berhasil dihapus ✓'),
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                );
              } catch (e) {
                late String message;
                if (e is ApiException && e.statusCode == 422) {
                  message = e.message;
                } else {
                  message = 'Gagal menghapus jenis vaksin';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helpers
  IconData _getAnimalIcon(String label) {
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

  IconData _getConditionIcon(String? conditionCode) {
    if (conditionCode == null) return Icons.note_alt_outlined;
    final lower = conditionCode.toLowerCase();
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

  // --- TAB BUILDERS ---

  Widget _buildProfileTab(Map<String, dynamic> farmData) {
    _initProfileFields(farmData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Form(
          key: _profileFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                labelText: 'Nama Peternakan *',
                  hintText: 'Contoh: Peternakan IPB',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 3) {
                    return 'Minimal 3 karakter';
                  }
                  if (name.length > 100) {
                    return 'Maksimal 100 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat *',
                  hintText: 'Contoh: Jl. Raya Dramaga...',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  final address = value?.trim() ?? '';
                  if (address.length < 3) {
                    return 'Minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pemilihan Lokasi (Latitude & Longitude)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_on,
                          color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Peta (Opsional)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_latController.text}, ${_lngController.text}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _handleSelectLocation,
                      child: const Text('Atur'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              // Deskripsi Peternakan
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  hintText: 'Jelaskan profil singkat peternakan Anda',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isSavingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSavingProfile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalTypesTab() {
    final animalTypesAsync = ref.watch(farmInfoAnimalTypesProvider);

    return animalTypesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, stack) => Center(child: Text('Gagal memuat jenis ternak: $err')),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyTabState(
            icon: Icons.pets_rounded,
            title: 'Belum Ada Jenis Ternak',
            desc: 'Tambahkan jenis ternak Anda dengan menekan tombol + di bawah.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 80),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final item = items[idx];
            final isCustom = item['farmId'] != null;

            return _buildParameterTile(
              title: item['label'] ?? '',
              icon: _getAnimalIcon(item['label']),
              color: AppTheme.primaryColor,
              onEdit: isCustom ? () => _showAnimalTypeDialog(item: item) : null,
              onDelete: isCustom ? () => _showDeleteAnimalTypeDialog(item) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildConditionTypesTab() {
    final conditionTypesAsync = ref.watch(farmInfoConditionTypesProvider);

    return conditionTypesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, stack) => Center(child: Text('Gagal memuat jenis kondisi: $err')),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyTabState(
            icon: Icons.health_and_safety_rounded,
            title: 'Belum Ada Jenis Kondisi',
            desc: 'Tambahkan jenis kondisi kustom Anda dengan menekan tombol + di bawah.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 80),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final item = items[idx];
            final isCustom = item['farmId'] != null;

            return _buildParameterTile(
              title: item['label'] ?? '',
              icon: _getConditionIcon(item['label']),
              color: const Color(0xFFF59E0B),
              onEdit: isCustom ? () => _showConditionTypeDialog(item: item) : null,
              onDelete: isCustom ? () => _showDeleteConditionTypeDialog(item) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildVaccinesTab() {
    final vaccinesAsync = ref.watch(farmInfoVaccinesProvider);

    return vaccinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (err, stack) => Center(child: Text('Gagal memuat jenis vaksin: $err')),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyTabState(
            icon: Icons.vaccines_rounded,
            title: 'Belum Ada Jenis Vaksin',
            desc: 'Tambahkan jenis vaksin kustom Anda dengan menekan tombol + di bawah.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 80),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final item = items[idx];
            final isCustom = item['farmId'] != null;

            return _buildParameterTile(
              title: item['name'] ?? '',
              icon: Icons.vaccines_rounded,
              color: const Color(0xFFEF4444),
              onEdit: isCustom ? () => _showVaccineDialog(item: item) : null,
              onDelete: isCustom ? () => _showDeleteVaccineDialog(item) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildParameterTile({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    final farmAsync = ref.watch(farmInfoDetailsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Info Peternakan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Profil', icon: Icon(Icons.business_rounded, size: 20)),
            Tab(text: 'Ternak', icon: Icon(Icons.pets_rounded, size: 20)),
            Tab(text: 'Kondisi', icon: Icon(Icons.health_and_safety_rounded, size: 20)),
            Tab(text: 'Vaksin', icon: Icon(Icons.vaccines_rounded, size: 20)),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          // Show FAB only for dynamic parameter tabs
          if (_tabController.index == 0) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 1) {
                _showAnimalTypeDialog();
              } else if (_tabController.index == 2) {
                _showConditionTypeDialog();
              } else if (_tabController.index == 3) {
                _showVaccineDialog();
              }
            },
            backgroundColor: _tabController.index == 1 ? AppTheme.primaryColor 
              : _tabController.index == 2 ? Color(0xFFF59E0B)
              : _tabController.index == 3 ? Color(0xFFEF4444)
              : AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
          );
        },
      ),
      body: farmAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat profil peternakan: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(farmInfoDetailsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (farmData) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(farmData),
              _buildAnimalTypesTab(),
              _buildConditionTypesTab(),
              _buildVaccinesTab(),
            ],
          );
        },
      ),
    );
  }
}
