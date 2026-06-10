import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/http_helper.dart';
import '../models/anggota_model.dart';
import 'auth_service.dart';

/// Service untuk CRUD Anggota
class AnggotaService {
  final AuthService _authService = AuthService();

  /// Header auth standar
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Sesi habis. Silakan login ulang.');
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/anggota — Ambil semua anggota
  Future<List<AnggotaModel>> getAnggotas() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/anggota'),
            headers: headers,
          )
          .timeout(ApiConstants.requestTimeout);

      final data = HttpHelper.handleResponse(response);

      // Response: { "data": { "anggotas": [...] } }
      List<dynamic> list = [];
      if (data['data'] is Map && data['data']['anggotas'] is List) {
        list = data['data']['anggotas'];
      } else if (data['data'] is List) {
        list = data['data'];
      } else if (data['anggotas'] is List) {
        list = data['anggotas'];
      }

      return list
          .map((json) => AnggotaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// GET /api/anggota/{id} — Detail satu anggota
  Future<AnggotaModel> getAnggotaById(int id) async {
    try {
      final headers = await _headers();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/anggota/$id'),
            headers: headers,
          )
          .timeout(ApiConstants.requestTimeout);

      final data = HttpHelper.handleResponse(response);

      // Response: { "data": { "id": ..., "nama": ... } }
      Map<String, dynamic> anggotaJson;
      if (data['data'] is Map && data['data']['anggota'] is Map) {
        anggotaJson = Map<String, dynamic>.from(data['data']['anggota']);
      } else if (data['data'] is Map) {
        anggotaJson = Map<String, dynamic>.from(data['data']);
      } else {
        anggotaJson = data;
      }

      return AnggotaModel.fromJson(anggotaJson);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// POST /api/anggota — Tambah anggota baru (multipart + opsional foto)
  Future<void> createAnggota(
    Map<String, String> fields, {
    XFile? imageFile,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Sesi habis.');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/anggota'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.fields.addAll(fields);

      // Tambah file foto jika ada
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: imageFile.name,
        ));
      }

      final streamedResponse =
          await request.send().timeout(ApiConstants.requestTimeout);
      await HttpHelper.handleStreamedResponse(streamedResponse);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// POST /api/anggota/{id} — Update anggota (multipart + _method: PUT)
  /// Menggunakan Laravel method spoofing karena form-data tidak support PUT
  Future<void> updateAnggota(
    int id,
    Map<String, String> fields, {
    XFile? imageFile,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Sesi habis.');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/anggota/$id'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Laravel method spoofing
      request.fields['_method'] = 'PUT';
      request.fields.addAll(fields);

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: imageFile.name,
        ));
      }

      final streamedResponse =
          await request.send().timeout(ApiConstants.requestTimeout);
      await HttpHelper.handleStreamedResponse(streamedResponse);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// DELETE /api/anggota/{id} — Hapus anggota
  Future<void> deleteAnggota(int id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/anggota/$id'),
            headers: headers,
          )
          .timeout(ApiConstants.requestTimeout);

      HttpHelper.handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }
}
