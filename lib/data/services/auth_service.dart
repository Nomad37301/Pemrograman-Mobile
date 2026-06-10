import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/http_helper.dart';
import '../models/user_model.dart';

/// Service untuk autentikasi: register, login, getUser, logout
/// Juga mengelola token via flutter_secure_storage
class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ─── Token Management ───

  Future<void> saveToken(String token) async {
    await _storage.write(key: ApiConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: ApiConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: ApiConstants.tokenKey);
  }

  /// Header standar untuk JSON request dengan auth
  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── API Endpoints ───

  /// POST /api/register
  /// Tidak memerlukan token
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(ApiConstants.requestTimeout);

      HttpHelper.handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// POST /api/login
  /// Menyimpan token otomatis ke secure storage
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConstants.requestTimeout);

      final data = HttpHelper.handleResponse(response);

      // Cari token di beberapa kemungkinan lokasi response
      String? token = data['token'] ??
          data['access_token'] ??
          (data['data'] is Map ? data['data']['token'] : null);

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan dalam respons server.');
      }

      await saveToken(token);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// GET /api/user
  /// Membutuhkan token
  Future<UserModel> getUser() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/user'),
            headers: headers,
          )
          .timeout(ApiConstants.requestTimeout);

      final data = HttpHelper.handleResponse(response);

      // Response: { "data": { "user": { ... }, "expired": "..." } }
      Map<String, dynamic> userData;
      if (data['data'] is Map && data['data']['user'] is Map) {
        userData = Map<String, dynamic>.from(data['data']['user']);
        userData['expired'] = data['data']['expired'];
      } else if (data['data'] is Map) {
        userData = Map<String, dynamic>.from(data['data']);
      } else if (data['user'] is Map) {
        userData = Map<String, dynamic>.from(data['user']);
      } else {
        userData = data;
      }

      return UserModel.fromJson(userData);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// GET /api/logout
  /// Menghapus token dari secure storage, error jaringan diabaikan
  Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/logout'),
            headers: headers,
          )
          .timeout(ApiConstants.requestTimeout);
    } catch (e) {
      // Sengaja diabaikan — token lokal tetap dihapus
      debugPrint('Logout API error (diabaikan): $e');
    }

    // Selalu hapus token lokal
    await deleteToken();
  }
}
