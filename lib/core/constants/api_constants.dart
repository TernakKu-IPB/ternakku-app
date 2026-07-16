class ApiConstants {
  // Gunakan 10.0.2.2 jika Anda menggunakan Android Emulator.
  // Gunakan localhost atau 127.0.0.1 jika menggunakan iOS Simulator.
  // Jika menggunakan perangkat fisik (HP asli), gunakan IP Address WiFi laptop Anda (misal: 192.168.1.x).
  static const String baseUrl = 'http://10.251.49.139:3000'; 
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User Endpoints
  static const String getProfile = '/users/me';

  // Farm Endpoints
  static const String getMyFarm = '/farms/me';
  static const String updateMyFarm = '/farms/me'; // PATCH

  // Master Data Custom
  static const String animalType = '/animal-types';
  static const String conditionType = '/condition-types';
  static const String vaccine = '/vaccines';

  // Template
  static const String animalTypeTemplate = '/animal-types/templates';
  static const String conditionTypeTemplate = '/condition-types/templates';
  static const String vaccineTemplate = '/vaccines/templates';

  // Livestock
  static const String livestock = '/livestocks';

  // Condition History (Catatan Harian)
  static const String conditionHistory = '/condition-histories';

  // Vaccination History (Rekam Medis)
  static const String vaccinationHistory = '/vaccination-histories';
}