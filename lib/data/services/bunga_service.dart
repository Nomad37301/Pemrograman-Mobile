import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/http_helper.dart';
import '../models/setting_bunga_model.dart';
import 'auth_service.dart';

/// Service untuk setting bunga: get setting + add setting baru
class BungaService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Sesi habis. Silakan login ulang.');
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/settingbunga
  /// Mengembalikan Map dengan key:
  ///   'active' : SettingBungaModel? (bisa null)
  ///   'history' : List of SettingBungaModel
  Future<Map<String, dynamic>> getSettingBunga() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/settingbunga'),
            headers: headers,
          )
          .timeout(ApiConstants.requestTimeout);

      final data = HttpHelper.handleResponse(response);

      // Parse active bunga
      SettingBungaModel? active;
      if (data['data'] is Map && data['data']['activebunga'] is Map) {
        active = SettingBungaModel.fromJson(
          Map<String, dynamic>.from(data['data']['activebunga']),
        );
      }

      // Parse history
      List<dynamic> settingList = [];
      if (data['data'] is Map && data['data']['settingbungas'] is List) {
        settingList = data['data']['settingbungas'];
      }

      final history = settingList
          .map((json) =>
              SettingBungaModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'active': active,
        'history': history,
      };
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// POST /api/addsettingbunga — Tambah setting bunga baru (multipart)
  Future<void> addSettingBunga({
    required String persen,
    required int isAktif,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Sesi habis.');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/addsettingbunga'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['persen'] = persen;
      request.fields['isaktif'] = isAktif.toString();

      final streamedResponse =
          await request.send().timeout(ApiConstants.requestTimeout);
      await HttpHelper.handleStreamedResponse(streamedResponse);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }
}
