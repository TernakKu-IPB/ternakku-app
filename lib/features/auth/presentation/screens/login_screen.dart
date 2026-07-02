import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/validators/app_validators.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // GlobalKey untuk form validasi
  final _formKey = GlobalKey<FormState>();

  // Controller untuk menangkap input teks
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  // State lokal untuk UI
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    // Selalu dispose controller untuk mencegah memory leak
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi simulasi login (akan kita ubah nanti untuk panggil API)
  void _onLoginPressed() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Hilangkan keyboard

      setState(() {
        _isLoading = true;
      });

      try {
        // Memanggil provider AuthController untuk login
        final authController = ref.read(authControllerProvider);
        await authController.login(
          _identifierController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Tampilkan pesan sukses warna hijau
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil masuk!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        if (e is ApiException) {
          debugPrint('Error terduga 2: ${e.fieldErrors.toString()}');
          // Jika backend mengirimkan error spesifik per field
          if (e.fieldErrors != null && e.fieldErrors!.isNotEmpty) {
            setState(() {
              _serverErrors = e.fieldErrors!;
            });
            _formKey.currentState!.validate(); // Trigger form supaya teks merah muncul
          } else {
            // Tampilkan error umum sebagai SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: Colors.red),
            );
          }
        } else {
          // Error tidak terduga lainnya
          debugPrint('Error tidak terduga');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey, // Bungkus dengan Form
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Aplikasi
                  Image.asset(
                    'assets/images/vertical-ternakku.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),
                  
                  // Teks Sambutan
                  Text(
                    'Selamat Datang',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk untuk mengelola peternakan Anda',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Form Input Identifier (Email/Username)
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama pengguna / email',
                      hintText: 'Masukkan nama pengguna atau email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (value) {
                      if (_serverErrors.containsKey('identifier')) {
                        setState(() => _serverErrors.remove('identifier'));
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      // 1. Cek dulu apakah ada error dari server
                      if (_serverErrors.containsKey('identifier')) {
                        return _serverErrors['identifier'];
                      }
                      // 2. Jika tidak ada, jalankan validasi lokal
                      return AppValidators.identifier(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Input Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Mengikuti state mata
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onLoginPressed(), // Bisa enter dari keyboard
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      hintText: 'Masukkan kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          // Toggle state mata
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      if (_serverErrors.containsKey('password')) {
                        setState(() => _serverErrors.remove('password'));
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      // 1. Cek dulu apakah ada error dari server
                      if (_serverErrors.containsKey('password')) {
                        return _serverErrors['password'];
                      }
                      // 2. Jika tidak ada, jalankan validasi lokal
                      final password = value ?? '';

                      if (password.length < 8) {
                        return 'Minimal 8 karakter';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.push('/forgot-password');
                            },
                      child: const Text('Lupa kata sandi?'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onLoginPressed, // Disable tombol saat loading
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Navigasi ke Halaman Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                context.push('/register');
                              },
                        child: Text(
                          'Daftar Sekarang',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}