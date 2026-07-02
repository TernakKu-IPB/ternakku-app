import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ternakku_app/core/network/api_exception.dart';
import 'package:ternakku_app/core/validators/app_validators.dart';
import '../providers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
      });

      try {
        final authController = ref.read(authControllerProvider);
        final successMessage = await authController.register(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

        if (!mounted) return;

        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage), // Misal: "Pendaftaran akun berhasil. Kode OTP..."
            backgroundColor: Colors.green,
          ),
        );

        // TODO: Arahkan ke Halaman Verifikasi OTP
        // context.go('/verify-otp');
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);
        
        if (e is ApiException) {
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
      // AppBar dengan tombol back
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Kembali ke halaman Login
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/vertical-ternakku.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Daftar Akun Baru',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lengkapi data di bawah untuk bergabung',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Form Nama Lengkap
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onChanged: (value) {
                      if (_serverErrors.containsKey('fullName')) {
                        setState(() => _serverErrors.remove('fullName'));
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      // 1. Cek dulu apakah ada error dari server
                      if (_serverErrors.containsKey('fullName')) {
                        return _serverErrors['fullName'];
                      }
                      // 2. Jika tidak ada, jalankan validasi lokal
                      return AppValidators.fullName(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Username
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama pengguna',
                      hintText: 'Masukkan nama pengguna',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (value) {
                      if (_serverErrors.containsKey('username')) {
                        setState(() => _serverErrors.remove('username'));
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      // 1. Cek dulu apakah ada error dari server
                      if (_serverErrors.containsKey('username')) {
                        return _serverErrors['username'];
                      }
                      // 2. Jika tidak ada, jalankan validasi lokal
                      return AppValidators.username(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Masukkan email aktif',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    onChanged: (value) {
                      if (_serverErrors.containsKey('email')) {
                        setState(() => _serverErrors.remove('email'));
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      // 1. Cek dulu apakah ada error dari server
                      if (_serverErrors.containsKey('email')) {
                        return _serverErrors['email'];
                      }
                      // 2. Jika tidak ada, jalankan validasi lokal
                      return AppValidators.email(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Kata Sandi
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      hintText: 'Minimal 8 karakter',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
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
                      return AppValidators.password(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Konfirmasi Kata Sandi
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onRegisterPressed(),
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi kata sandi',
                      hintText: 'Ulangi kata sandi',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                    ),
                    onChanged: (value) {
                      if (_serverErrors.containsKey('confirmPassword')) {
                        setState(() => _serverErrors.remove('confirmPassword'));
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      // 1. Cek dulu apakah ada error dari server
                      if (_serverErrors.containsKey('confirmPassword')) {
                        return _serverErrors['confirmPassword'];
                      }
                      // 2. Jika tidak ada, jalankan validasi lokal
                      if (value == null || value.isEmpty) return 'Konfirmasi kata sandi tidak boleh kosong';
                      if (value != _passwordController.text) return 'Kata sandi tidak cocok';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Tombol Daftar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onRegisterPressed,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}