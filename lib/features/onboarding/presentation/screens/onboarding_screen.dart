import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';
import 'package:ternakku_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ternakku_app/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:ternakku_app/features/onboarding/presentation/providers/template_providers.dart';
import 'package:ternakku_app/features/onboarding/presentation/screens/farm_profile_step.dart';
import 'package:ternakku_app/features/onboarding/presentation/screens/animal_type_step.dart';
import 'package:ternakku_app/features/onboarding/presentation/screens/condition_type_step.dart';
import 'package:ternakku_app/features/onboarding/presentation/screens/vaccine_step.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
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

  // ==========================================
  // State Langkah 2 (Animal Types)
  // ==========================================

  final List<int> _selectedAnimalTemplateIds = [];
  final List<Map<String, String>> _customAnimalTypes = [];

  void _toggleAnimalTemplate(int id) {
    setState(() {
      if (_selectedAnimalTemplateIds.contains(id)) {
        _selectedAnimalTemplateIds.remove(id);
      } else {
        _selectedAnimalTemplateIds.add(id);
      }
    });
  }

  void _addCustomAnimalType(String label, String code) {
    final templates = ref.read(animalTemplatesProvider).value ?? [];
    final animalTemplate = templates.firstWhere(
      (e) => e['code'] == code,
      orElse: () => <String, dynamic>{},
    );
    if (animalTemplate.isNotEmpty) {
      setState(() {
        _selectedAnimalTemplateIds.add(animalTemplate['id']);
      });
    } else if (_customAnimalTypes.any((e) => e['code'] == code)) {
      _showErrorSnackBar('Jenis ternak "$label" sudah ada.');
    } else {
      setState(() {
        _customAnimalTypes.add({'label': label, 'code': code});
      });
    }
  }

  void _removeCustomAnimalType(int index) {
    setState(() {
      _customAnimalTypes.removeAt(index);
    });
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

  // ==========================================
  // State Langkah 3 (Condition Types)
  // ==========================================

  final List<int> _selectedConditionTemplateIds = [];
  final List<Map<String, String>> _customConditionTypes = [];

  void _toggleConditionTemplate(int id) {
    setState(() {
      if (_selectedConditionTemplateIds.contains(id)) {
        _selectedConditionTemplateIds.remove(id);
      } else {
        _selectedConditionTemplateIds.add(id);
      }
    });
  }

  void _addCustomConditionType(String label, String code) {
    final templates = ref.read(conditionTemplatesProvider).value ?? [];
    final conditionTemplate = templates.firstWhere(
      (e) => e['code'] == code,
      orElse: () => <String, dynamic>{},
    );
    if (conditionTemplate.isNotEmpty) {
      setState(() {
        _selectedConditionTemplateIds.add(conditionTemplate['id']);
      });
    } else if (_customConditionTypes.any((e) => e['code'] == code)) {
      _showErrorSnackBar('Kondisi ternak "$label" sudah ada.');
    } else {
      setState(() {
        _customConditionTypes.add({'label': label, 'code': code});
      });
    }
  }

  void _removeCustomConditionType(int index) {
    setState(() {
      _customConditionTypes.removeAt(index);
    });
  }

  // ==========================================
  // State Langkah 4 (Vaccines)
  // ==========================================

  final List<int> _selectedVaccineTemplateIds = [];
  final List<Map<String, String>> _customVaccines = [];

  void _toggleVaccineTemplate(int id) {
    setState(() {
      if (_selectedVaccineTemplateIds.contains(id)) {
        _selectedVaccineTemplateIds.remove(id);
      } else {
        _selectedVaccineTemplateIds.add(id);
      }
    });
  }

  void _addCustomVaccine(String label, String code) {
    final templates = ref.read(vaccineTemplatesProvider).value ?? [];
    final vaccineTemplate = templates.firstWhere(
      (e) => e['code'] == code,
      orElse: () => <String, dynamic>{},
    );
    if (vaccineTemplate.isNotEmpty) {
      setState(() {
        _selectedVaccineTemplateIds.add(vaccineTemplate['id']);
      });
    } else if (_customVaccines.any((e) => e['code'] == code)) {
      _showErrorSnackBar('Jenis vaksin "$label" sudah ada.');
    } else {
      setState(() {
        _customVaccines.add({'label': label, 'code': code});
      });
    }
  }

  void _removeCustomVaccine(int index) {
    setState(() {
      _customVaccines.removeAt(index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentIndex == 0) {
      if (!_profileFormKey.currentState!.validate()) {
        return; 
      }
    } else if (_currentIndex == 1) {
      // Validasi: Pastikan user minimal memilih/membuat 1 jenis ternak
      if (_selectedAnimalTemplateIds.isEmpty && _customAnimalTypes.isEmpty) {
        _showErrorSnackBar('Pilih atau tambahkan minimal 1 jenis ternak.');
        return;
      }
    } else if (_currentIndex == 2) {
      // Validasi Langkah 3: Minimal 1 kondisi (opsional, tapi disarankan untuk aplikasi pencatatan)
      if (_selectedConditionTemplateIds.isEmpty && _customConditionTypes.isEmpty) {
        _showErrorSnackBar('Pilih atau tambahkan minimal 1 kondisi ternak.');
        return;
      }
    } else if (_currentIndex == 3) {
      if (_selectedVaccineTemplateIds.isEmpty && _customVaccines.isEmpty) {
        _showErrorSnackBar('Pilih atau tambahkan minimal 1 jenis vaksin.');
        return;
      }
      
      await _submitAllData();
      return; 
    }

    // Pindah halaman jika belum mencapai akhir
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

      // --- 1. Ambil Data Referensi Template dari Riverpod ---
      final animalTpls = ref.read(animalTemplatesProvider).value ?? [];
      final conditionTpls = ref.read(conditionTemplatesProvider).value ?? [];
      final vaccineTpls = ref.read(vaccineTemplatesProvider).value ?? [];

      // --- 2. Gabungkan Animal Types (Template + Custom) ---
      final finalAnimalTypes = [..._customAnimalTypes];
      for (var id in _selectedAnimalTemplateIds) {
        final tpl = animalTpls.firstWhere((e) => e['id'] == id);
        finalAnimalTypes.add({'code': tpl['code'], 'label': tpl['label']});
      }

      // --- 3. Gabungkan Condition Types (Template + Custom) ---
      final finalConditionTypes = [..._customConditionTypes];
      for (var id in _selectedConditionTemplateIds) {
        final tpl = conditionTpls.firstWhere((e) => e['id'] == id);
        finalConditionTypes.add({'code': tpl['code'], 'label': tpl['label']});
      }

      // --- 4. Gabungkan Vaccines (Template + Custom) ---
      final finalVaccines = [..._customVaccines];
      for (var id in _selectedVaccineTemplateIds) {
        final tpl = vaccineTpls.firstWhere((e) => e['id'] == id);
        final labelOrName = tpl['name'] ?? tpl['label']; 
        finalVaccines.add({'code': tpl['code'], 'label': labelOrName}); 
      }
      
      await controller.submitOnboarding(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        allAnimalTypes: finalAnimalTypes,
        allConditionTypes: finalConditionTypes,
        allVaccines: finalVaccines,
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
    final animalTemplatesAsync = ref.watch(animalTemplatesProvider);
    final conditionTemplatesAsync = ref.watch(conditionTemplatesProvider);
    final vaccineTemplatesAsync = ref.watch(vaccineTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Persiapan Peternakan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: _currentIndex > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indikator Progress
            _buildProgressIndicator(),
            const SizedBox(height: 16),

            // Konten Halaman Form
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Kunci geser manual
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  // Langkah 1: Profil Peternakan
                  FarmProfileStep(
                    formKey: _profileFormKey,
                    nameController: _nameController,
                    addressController: _addressController,
                    descController: _descController,
                    onSelectLocation: _handleSelectLocation,
                    latitude: _latitude,
                    longitude: _longitude,
                  ),
                  
                  // Langkah 2: Jenis Ternak
                  animalTemplatesAsync.when(
                    data: (templates) => AnimalTypeStep(
                      templates: templates,
                      selectedTemplateIds: _selectedAnimalTemplateIds,
                      onToggleTemplate: _toggleAnimalTemplate,
                      customTypes: _customAnimalTypes,
                      onAddCustomType: _addCustomAnimalType,
                      onRemoveCustomType: _removeCustomAnimalType,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Center(child: Text('Gagal memuat template jenis ternak')),
                  ),
                  
                  // Langkah 3: Kondisi Ternak
                  conditionTemplatesAsync.when(
                    data: (templates) => ConditionTypeStep(
                      templates: templates,
                      selectedTemplateIds: _selectedConditionTemplateIds,
                      onToggleTemplate: _toggleConditionTemplate,
                      customTypes: _customConditionTypes,
                      onAddCustomType: _addCustomConditionType,
                      onRemoveCustomType: _removeCustomConditionType,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Center(child: Text('Gagal memuat template kondisi ternak')),
                  ),
                  
                  // Langkah 4: Vaksin
                  vaccineTemplatesAsync.when(
                    data: (templates) => VaccineStep(
                      templates: templates,
                      selectedTemplateIds: _selectedVaccineTemplateIds,
                      onToggleTemplate: _toggleVaccineTemplate,
                      customTypes: _customVaccines,
                      onAddCustomType: _addCustomVaccine,
                      onRemoveCustomType: _removeCustomVaccine,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Center(child: Text('Gagal memuat template vaksin')),
                  ),
                ],
              ),
            ),

            // Kumpulan Tombol Navigasi Bawah (Bottom Bar)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentIndex > 0) ...[
                    OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kembali'),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextPage,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_currentIndex == 3 ? 'Selesai' : 'Lanjutkan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / 5;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final isPassed = index < _currentIndex;
                  final isCurrent = index == _currentIndex;
                  return Container(
                    width: width,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isPassed
                          ? AppTheme.primaryColor
                          : isCurrent
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Langkah ${_currentIndex + 1} dari 4: ${_getStepTitle()}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Profil Peternakan';
      case 1:
        return 'Jenis Ternak';
      case 2:
        return 'Kondisi Ternak';
      case 3:
        return 'Vaksinasi';
      default:
        return '';
    }
  }
}