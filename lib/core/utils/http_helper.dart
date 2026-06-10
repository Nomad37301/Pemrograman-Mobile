import 'dart:convert';
import 'package:http/http.dart' as http;

/// Helper class untuk menangani HTTP response secara konsisten
class HttpHelper {
  HttpHelper._();

  /// Parse dan validasi HTTP response.
  /// Throw Exception dengan pesan user-friendly jika status bukan 2xx.
  static Map<String, dynamic> handleResponse(http.Response response) {
    Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
        'Server mengembalikan format yang tidak dikenali (${response.statusCode})',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    // Error handling per status code
    switch (response.statusCode) {
      case 400:
        throw Exception(
          responseBody['message'] ?? 'Permintaan tidak valid.',
        );
      case 401:
      case 405:
        throw Exception(
          'Email atau Password salah! Silakan coba lagi.',
        );
      case 403:
        throw Exception(
          responseBody['message'] ?? 'Akses ditolak.',
        );
      case 404:
        throw Exception('Layanan tidak ditemukan.');
      case 422:
        final errors = responseBody['errors'];
        if (errors != null && errors is Map) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first.toString());
          }
        }
        throw Exception('Data yang dimasukkan tidak valid.');
      case 429:
        throw Exception(
          'Terlalu banyak percobaan. Tunggu beberapa saat.',
        );
      case 500:
        throw Exception('Terjadi kesalahan pada server (500).');
      case 502:
        throw Exception('Server sedang tidak tersedia (502).');
      case 503:
        throw Exception('Layanan sedang dalam pemeliharaan (503).');
      default:
        throw Exception(
          responseBody['message'] ??
              'Terjadi kesalahan (HTTP ${response.statusCode}).',
        );
    }
  }

  /// Parse dan validasi streamed response (untuk MultipartRequest).
  static Future<Map<String, dynamic>> handleStreamedResponse(
    http.StreamedResponse streamedResponse,
  ) async {
    final response = await http.Response.fromStream(streamedResponse);
    return handleResponse(response);
  }
}
