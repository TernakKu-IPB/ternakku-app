class AppValidators {
  static String? identifier(String? value) {
    final identifier = value?.trim() ?? '';

    if (identifier.length < 3) {
      return 'Minimal 3 karakter';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!usernameRegex.hasMatch(identifier) &&
        !emailRegex.hasMatch(identifier)) {
      return 'Nama pengguna atau email tidak valid';
    }

    return null;
  }

  static String? username(String? value) {
    final val = value?.trim() ?? '';

    if (val.length < 3) {
      return 'Minimal 3 karakter';
    }

    if (val.length > 20) {
      return 'Maksimal 20 karakter';
    }

    final usernameRegex = RegExp(
      r'^(?!_)(?!.*__)[a-zA-Z0-9_]+(?<!_)$',
    );

    if (!usernameRegex.hasMatch(val)) {
      return 'Hanya boleh berisi huruf, angka, dan garis bawah, tetapi tidak boleh dimulai atau diakhiri dengan garis bawah';
    }

    return null;
  }

  static String? email(String? value) {
    final val = value?.trim() ?? '';
    if (val.isEmpty) return 'Email tidak boleh kosong';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
      return 'Email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';

    if (password.length < 8) {
      return 'Minimal 8 karakter';
    }

    if (password.length > 64) {
      return 'Maksimal 64 karakter';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Setidaknya berisi satu huruf kapital';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Setidaknya berisi satu huruf kecil';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Setidaknya berisi satu angka';
    }

    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) {
      return 'Setidaknya berisi satu spesial karakter (@\$!%*?&)';
    }

    return null;
  }

  static String? fullName(String? value) {
    final val = value?.trim() ?? '';
    if (val.length < 3) {
      return 'Minimal 3 karakter';
    }
    if (val.length > 100) {
      return 'Maksimal 100 karakter';
    }
    return null;
  }
}