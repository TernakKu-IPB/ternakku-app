import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ternakku_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ternakku_app/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLoading = false;

  // ==========================================
  // State Langka 1 (Profil Peternakan)
  // ==========================================
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  String? _latitude;
  String? _longitude;


  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSelectLocation() {
    // Nanti di sini kita bisa integrasikan paket koordinat atau mock data terlebih dahulu
    setState(() {
      _latitude = "-6.5599125";
      _longitude = "106.7255118";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokasi berhasil disematkan (Mock Data)')),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitAllData() async {
    setState(() => _isLoading = true);

    try {
      final controller = ref.read(onboardingControllerProvider);
      
      await controller.submitOnboarding(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peternakan berhasil dikonfigurasi!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Update state auth agar hasFarm = true
        ref.read(authProvider.notifier).markAsHasFarm();
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Persiapan Peternakan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _profileFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profil Peternakan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lengkapi data peternakan Anda sebelum melakukan pencatatan ternak.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 24),

                // Nama Peternakan
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

                // Alamat Peternakan
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
                              _latitude != null && _longitude != null
                                  ? '$_latitude, $_longitude'
                                  : 'Belum diatur',
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
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitAllData,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}