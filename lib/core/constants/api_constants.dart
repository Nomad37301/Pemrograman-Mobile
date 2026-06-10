/// Konfigurasi API global
class ApiConstants {
  ApiConstants._(); // Prevent instantiation

  /// Base URL untuk semua endpoint API
  static const String baseUrl = 'https://mobileapis.manpits.xyz/api';

  /// Durasi timeout untuk setiap HTTP request
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Key untuk menyimpan token di secure storage
  static const String tokenKey = 'auth_token';
}
