import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ternakku_app/core/theme/app_theme.dart';

class VaccineStep extends StatelessWidget {
  final List<Map<String, dynamic>> templates;
  final List<int> selectedTemplateIds;
  final Function(int) onToggleTemplate;
  
  final List<Map<String, String>> customTypes;
  final Function(String label, String code) onAddCustomType;
  final Function(int) onRemoveCustomType;

  const VaccineStep({
    super.key,
    required this.templates,
    required this.selectedTemplateIds,
    required this.onToggleTemplate,
    required this.customTypes,
    required this.onAddCustomType,
    required this.onRemoveCustomType,
  });

  void _showAddCustomDialog(BuildContext context) {
    final labelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Tambah Jenis Vaksin',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
              controller: labelController,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final label = labelController.text.trim();
                  final code = label.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
                  onAddCustomType(label, code);
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen Vaksin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih jenis vaksin yang umum digunakan di peternakan Anda. Ini akan memudahkan penjadwalan dan pencatatan rekam medis ternak.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),

          Text(
            'Vaksin Umum (Rekomendasi)',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: templates.map((template) {
              final isSelected = selectedTemplateIds.contains(template['id']);
              return FilterChip(
                label: Text(template['name']),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                selected: isSelected,
                onSelected: (bool selected) => onToggleTemplate(template['id']),
                backgroundColor: AppTheme.scaffoldBackground,
                selectedColor: AppTheme.primaryColor,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          Text(
            'Vaksin Lainnya?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          
          if (customTypes.isNotEmpty) ...[
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: List.generate(customTypes.length, (index) {
                return Chip(
                  label: Text(customTypes[index]['label']!),
                  // Menggunakan .withValues(alpha: 0.1) sesuai instruksi terbaru
                  backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  side: const BorderSide(color: AppTheme.secondaryColor),
                  deleteIconColor: AppTheme.secondaryColor,
                  onDeleted: () => onRemoveCustomType(index),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: () => _showAddCustomDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Vaksin Sendiri'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}