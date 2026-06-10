import 'package:flutter/material.dart';
import '../../data/models/anggota_model.dart';
import '../../data/services/anggota_service.dart';
import 'anggota_form_page.dart';

/// Halaman detail anggota — GET /api/anggota/{id}
/// Menampilkan info lengkap + link ke tabungan
class AnggotaDetailPage extends StatefulWidget {
  final int anggotaId;
  const AnggotaDetailPage({super.key, required this.anggotaId});

  @override
  State<AnggotaDetailPage> createState() => _AnggotaDetailPageState();
}

class _AnggotaDetailPageState extends State<AnggotaDetailPage> {
  final _anggotaService = AnggotaService();
  AnggotaModel? _anggota;
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final anggota = await _anggotaService.getAnggotaById(widget.anggotaId);
      if (mounted) {
        setState(() {
          _anggota = anggota;
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

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Anggota', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_anggota != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnggotaFormPage(anggotaId: widget.anggotaId),
                  ),
                );
                if (result == true) _fetchDetail();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMsg!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchDetail, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _anggota == null
                  ? const Center(child: Text('Data tidak ditemukan.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Avatar & Nama
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              _anggota!.nama.isNotEmpty ? _anggota!.nama[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _anggota!.nama,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),

                          // Info tiles
                          _infoTile(Icons.badge, 'Nomor Induk', _anggota!.nomorInduk.toString()),
                          _infoTile(Icons.home, 'Alamat', _anggota!.alamat),
                          _infoTile(Icons.cake, 'Tanggal Lahir', _anggota!.tglLahir),
                          _infoTile(Icons.phone, 'Telepon', _anggota!.telepon),
                          _infoTile(
                            Icons.check_circle,
                            'Status Aktif',
                            _anggota!.statusAktif == 1 ? 'Aktif' : 'Tidak Aktif',
                          ),
                        ],
                      ),
                    ),
    );
  }
}
