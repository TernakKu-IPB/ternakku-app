import 'package:flutter/material.dart';

class FarmProfileStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController descController;
  
  // Karena kordinat butuh peta, untuk MVP kita buat read-only dengan tombol "Pilih di Peta"
  final VoidCallback onSelectLocation; 
  final String? latitude;
  final String? longitude;

  const FarmProfileStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.addressController,
    required this.descController,
    required this.onSelectLocation,
    this.latitude,
    this.longitude,
  });

  @override
  State<FarmProfileStep> createState() => _FarmProfileStepState();
}

class _FarmProfileStepState extends State<FarmProfileStep> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              controller: widget.nameController,
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
              controller: widget.addressController,
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
                          widget.latitude != null && widget.longitude != null
                              ? '${widget.latitude}, ${widget.longitude}'
                              : 'Belum diatur',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onSelectLocation,
                    child: const Text('Atur'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Deskripsi Peternakan
            TextFormField(
              controller: widget.descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Jelaskan profil singkat peternakan Anda',
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}