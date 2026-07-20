import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/validators/app_validators.dart';
import '../providers/auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);

      try {
        final authController = ref.read(authControllerProvider);
        final message = await authController.resetPassword(
          token: widget.token,
          newPassword: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          if (e is ApiException && e.fieldErrors != null && e.fieldErrors!.isNotEmpty) {
            setState(() => _serverErrors = e.fieldErrors!);
            _formKey.currentState!.validate();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Token tidak valid atau tidak ditemukan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Kata Sandi Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 80, color: Colors.teal),
                const SizedBox(height: 24),
                Text(
                  'Amankan Akun Anda',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Kata sandi baru',
                    errorMaxLines: 2,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  onChanged: (_) {
                    if (_serverErrors.containsKey('newPassword')) {
                      setState(() => _serverErrors.remove('newPassword'));
                      _formKey.currentState!.validate();
                    }
                  },
                  validator: (value) {
                    if (_serverErrors.containsKey('newPassword')) return _serverErrors['newPassword'];
                    return AppValidators.password(value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi kata sandi baru',
                    errorMaxLines: 2,
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Tidak boleh kosong';
                    if (value != _passwordController.text) return 'Kata sandi tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Simpan Kata Sandi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}