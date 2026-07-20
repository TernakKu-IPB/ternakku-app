class PasswordRule {
  final String description;
  final bool Function(String password) check;

  const PasswordRule({
    required this.description,
    required this.check,
  });
}

final List<PasswordRule> passwordRules = [
  PasswordRule(
    description: 'Minimal 8 karakter',
    check: (p) => p.length >= 8,
  ),
  PasswordRule(
    description: 'Maksimal 64 karakter',
    check: (p) => p.length <= 64,
  ),
  PasswordRule(
    description: 'Mengandung huruf kapital',
    check: (p) => RegExp(r'[A-Z]').hasMatch(p),
  ),
  PasswordRule(
    description: 'Mengandung huruf kecil',
    check: (p) => RegExp(r'[a-z]').hasMatch(p),
  ),
  PasswordRule(
    description: 'Mengandung angka',
    check: (p) => RegExp(r'[0-9]').hasMatch(p),
  ),
  PasswordRule(
    description: r'Mengandung karakter spesial (@$!%*?&)',
    check: (p) => RegExp(r'[@$!%*?&]').hasMatch(p),
  ),
];
