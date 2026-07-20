import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // Profile Form Controllers
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isSavingProfile = false;

  @override
  void dispose() {
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
          _initProfileFields(farmData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
                key: _profileFormKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cottage_rounded,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Kelola Profil Peternakan',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
          );
        },
      ),
    );
  }
}
