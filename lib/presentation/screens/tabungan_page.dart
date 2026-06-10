import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/tabungan_model.dart';
import '../../data/models/jenis_transaksi_model.dart';
import '../../data/services/tabungan_service.dart';
import 'form_transaksi_bottom_sheet.dart';

/// Halaman tabungan anggota — menampilkan saldo + riwayat transaksi.
/// Menggunakan parallel request: GET /api/saldo/{id} + GET /api/tabungan/{id}
class TabunganPage extends StatefulWidget {
  final int anggotaId;
  final String anggotaNama;

  const TabunganPage({
    super.key,
    required this.anggotaId,
    required this.anggotaNama,
  });

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  // ─── SERVICES & FORMATTERS ───
  // Service untuk memanggil API tabungan (saldo, list transaksi, tambah transaksi)
  final _tabunganService = TabunganService();
  
  // Format mata uang Rupiah Indonesia (contoh: Rp 1.500.000)
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // ─── STATE VARIABLES ───
  // Menyimpan saldo aktif anggota
  double _saldo = 0.0;
  // Menyimpan riwayat transaksi tabungan anggota
  List<TabunganModel> _riwayat = [];
  // Menyimpan jenis-jenis transaksi (seperti Simpanan, Penarikan, Bunga, dll)
  List<JenisTransaksiModel> _jenisTransaksi = [];
  // Loading status halaman
  bool _isLoading = true;
  // Menyimpan pesan error jika request gagal
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Memulai request API paralel saat halaman dimuat
    _loadData();
  }

  // ─── REQUEST PARALEL KE SERVER ───
  // Mempercepat loading dengan menjalankan request Saldo dan Riwayat sekaligus secara paralel
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // Future.wait menjalankan list request ini bersamaan di background
      final results = await Future.wait([
        _tabunganService.getDetailTabungan(widget.anggotaId),
        _tabunganService.getJenisTransaksi(),
      ]);

      // Mengambil hasil response
      final detail = results[0] as Map<String, dynamic>;
      final jenisList = results[1] as List<JenisTransaksiModel>;

      if (mounted) {
        setState(() {
          _saldo = detail['saldo'] as double;
          _riwayat = detail['riwayat'] as List<TabunganModel>;
          _jenisTransaksi = jenisList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // ─── UTILITY FUNCTIONS ───
  
  /// Cari nama jenis transaksi berdasarkan trxId (id di database)
  String _getJenisNama(int trxId) {
    final jenis = _jenisTransaksi.where((j) => j.id == trxId);
    return jenis.isNotEmpty ? jenis.first.namaTrx : 'Transaksi #$trxId';
  }

  /// Cek apakah transaksi ini menambah saldo (multiplier = 1) atau mengurangi (multiplier = -1)
  int _getMultiplier(int trxId) {
    final jenis = _jenisTransaksi.where((j) => j.id == trxId);
    return jenis.isNotEmpty ? jenis.first.multiplier : 1;
  }

  // ─── BOTTOM SHEET INPUT TRANSAKSI ───
  // Menampilkan modal dialog bottom sheet dari bawah layar untuk menambah transaksi baru
  void _showTambahTransaksi() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Membuat bottom sheet bisa naik ke atas ketika keyboard HP terbuka
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FormTransaksiBottomSheet(
        anggotaId: widget.anggotaId,
        jenisTransaksi: _jenisTransaksi,
        onSuccess: _loadData, // Callback untuk memicu refresh data halaman ini setelah transaksi sukses
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabungan - ${widget.anggotaNama}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple, // UBAH WARNA APPBAR DI SINI
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Floating Action Button (FAB) di kanan bawah untuk tambah transaksi
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showTambahTransaksi,
        backgroundColor: Colors.deepPurple, // UBAH WARNA FAB DI SINI
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      // ─── KONDISIONAL BODY ───
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMsg!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ─── CONTAINER CARD SALDO ANGGOTA ───
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          // Efek gradasi warna background ungu di kartu saldo
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent], // UBAH WARNA GRADIENT DI SINI
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saldo Saat Ini',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currencyFormat.format(_saldo),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── RIWAYAT TRANSAKSI LIST HEADER ───
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (_riwayat.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Belum ada transaksi.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        // Looping riwayat transaksi dan menampilkannya sebagai widget Card
                        ..._riwayat.map((trx) {
                          final multiplier = _getMultiplier(trx.trxId);
                          // Jika multiplier >= 0 berarti transaksi kredit/menambah saldo (tampilkan warna hijau)
                          // Jika multiplier < 0 berarti transaksi debet/mengurangi saldo (tampilkan warna merah)
                          final isCredit = multiplier >= 0;

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              // Ikon indikator arah panah (masuk / keluar)
                              leading: CircleAvatar(
                                backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                                child: Icon(
                                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isCredit ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                _getJenisNama(trx.trxId),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(trx.tanggal),
                              
                              // Menampilkan nominal bertanda plus (+) atau minus (-) dengan warna yang sesuai
                              trailing: Text(
                                '${isCredit ? '+' : '-'} ${_currencyFormat.format(trx.nominal)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCredit ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
