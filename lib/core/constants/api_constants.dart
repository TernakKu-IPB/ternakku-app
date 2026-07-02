class ApiConstants {
  // Gunakan 10.0.2.2 jika Anda menggunakan Android Emulator.
  // Gunakan localhost atau 127.0.0.1 jika menggunakan iOS Simulator.
  // Jika menggunakan perangkat fisik (HP asli), gunakan IP Address WiFi laptop Anda (misal: 192.168.1.x).
  static const String baseUrl = 'http://192.168.0.108:3000'; 
  
  // Endpoint Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';

  // Endpoint User
  static const String getProfile = '/users/me';
}