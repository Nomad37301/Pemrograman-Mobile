import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/http_helper.dart';
import '../models/tabungan_model.dart';
import '../models/jenis_transaksi_model.dart';
import 'auth_service.dart';

/// Service untuk tabungan: jenis transaksi, saldo, riwayat, dan tambah transaksi
class TabunganService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Sesi habis. Silakan login ulang.');
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/jenistransaksi — List jenis transaksi
  Future<List<JenisTransaksiModel>> getJenisTransaksi() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/jenistransaksi'),
            headers: headers,
          )
          .timeout(ApiConstants.requestTimeout);

      final data = HttpHelper.handleResponse(response);

      // Response: { "data": { "jenistransaksi": [...] } }
      List<dynamic> list = [];
      if (data['data'] is Map && data['data']['jenistransaksi'] is List) {
        list = data['data']['jenistransaksi'];
      } else if (data['data'] is List) {
        list = data['data'];
      }

      return list
          .map((json) =>
              JenisTransaksiModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// GET /api/saldo/{id} + GET /api/tabungan/{id} — paralel
  /// Mengembalikan Map dengan key 'saldo' (double) dan 'riwayat' (List of TabunganModel)
  Future<Map<String, dynamic>> getDetailTabungan(int anggotaId) async {
    try {
      final headers = await _headers();

      // Parallel request menggunakan Future.wait
      final responses = await Future.wait([
        http
            .get(
              Uri.parse('${ApiConstants.baseUrl}/saldo/$anggotaId'),
              headers: headers,
            )
            .timeout(ApiConstants.requestTimeout),
        http
            .get(
              Uri.parse('${ApiConstants.baseUrl}/tabungan/$anggotaId'),
              headers: headers,
            )
            .timeout(ApiConstants.requestTimeout),
      ]);

      final saldoData = HttpHelper.handleResponse(responses[0]);
      final riwayatData = HttpHelper.handleResponse(responses[1]);

      // Parse saldo: { "data": { "saldo": "1500000.00" } }
      double saldo = 0.0;
      if (saldoData['data'] is Map && saldoData['data']['saldo'] != null) {
        saldo =
            double.tryParse(saldoData['data']['saldo'].toString()) ?? 0.0;
      }

      // Parse riwayat: { "data": { "tabungan": [...] } }
      List<dynamic> tabunganList = [];
      if (riwayatData['data'] is Map &&
          riwayatData['data']['tabungan'] is List) {
        tabunganList = riwayatData['data']['tabungan'];
      }

      final riwayat = tabunganList
          .map((json) =>
              TabunganModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'saldo': saldo,
        'riwayat': riwayat,
      };
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }

  /// POST /api/tabungan — Tambah transaksi (multipart/form-data)
  Future<void> tambahTransaksi({
    required int anggotaId,
    required int trxId,
    required String nominal,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Sesi habis.');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/tabungan'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['anggota_id'] = anggotaId.toString();
      request.fields['trx_id'] = trxId.toString();
      request.fields['trx_nominal'] = nominal;

      final streamedResponse =
          await request.send().timeout(ApiConstants.requestTimeout);
      await HttpHelper.handleStreamedResponse(streamedResponse);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    }
  }
}
