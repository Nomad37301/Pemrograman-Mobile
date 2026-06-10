import 'package:flutter/material.dart';
import '../../data/models/anggota_model.dart';
import '../../data/services/anggota_service.dart';
import 'tabungan_page.dart';

/// Halaman Transaksi Tabungan — memuat daftar anggota untuk dipilih.
/// Anggota yang dipilih akan diarahkan ke halaman detail tabungan mereka.
class TransaksiTabunganPage extends StatefulWidget {
  const TransaksiTabunganPage({super.key});

  @override
  State<TransaksiTabunganPage> createState() => _TransaksiTabunganPageState();
}

class _TransaksiTabunganPageState extends State<TransaksiTabunganPage> {
  // ─── INSTANCE SERVICES ───
  // Service untuk memanggil API anggota (list, get, detail)
  final _anggotaService = AnggotaService();

  // ─── STATE VARIABLES ───
  // Menyimpan list mentah semua anggota dari API
  List<AnggotaModel> _anggotaList = [];
  // Loading status saat memanggil API
  bool _isLoading = true;
  // Menyimpan pesan error jika request API gagal
  String? _errorMsg;

  // ─── CONTROLLERS & STATE UNTUK PENCARIAN ───
  // Controller untuk membaca inputan text dari search bar
  final _searchController = TextEditingController();
  // Menyimpan string query pencarian yang aktif
  String _searchQuery = '';

  // ─── LOGIC PENCARIAN (FILTER) ───
  // Getter ini menyaring daftar anggota secara real-time berdasarkan query.
  // Menyaring berdasarkan: Nama (case insensitive) ATAU Nomor Induk.
  List<AnggotaModel> get _filteredList {
    if (_searchQuery.isEmpty) return _anggotaList;
    final q = _searchQuery.toLowerCase();
    return _anggotaList.where((a) {
      return a.nama.toLowerCase().contains(q) ||
          a.nomorInduk.toString().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Memulai request API anggota saat halaman pertama kali dibuka
    _fetchAnggota();
  }

  @override
  void dispose() {
    // Selalu dispose controller untuk mencegah kebocoran memori (memory leak)
    _searchController.dispose();
    super.dispose();
  }

  // ─── METHOD REQUEST API ───
  // Mengambil daftar anggota dari service dan mengupdate state widget
  Future<void> _fetchAnggota() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final list = await _anggotaService.getAnggotas();
      if (mounted) {
        setState(() {
          _anggotaList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Membersihkan prefix 'Exception: ' agar pesan error ramah pengguna
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // List yang akan ditampilkan setelah disaring oleh kolom pencarian
    final displayList = _filteredList;
    
    return Scaffold(
      // ─── APP BAR (BAGIAN ATAS) ───
      appBar: AppBar(
        title: const Text('Transaksi Tabungan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple, // UBAH WARNA APPBAR DI SINI
        iconTheme: const IconThemeData(color: Colors.white),
        
        // ─── SEARCH BAR DI BAWAH TITLE APP BAR ───
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val), // Memicu re-build widget saat mengetik
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor induk...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                
                // Tombol 'X' untuk menghapus teks pencarian jika tidak kosong
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15), // Background transparan putih di dalam search bar
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      
      // ─── BODY UTAMA (KONDISIONAL BERDASARKAN STATE) ───
      body: _isLoading
          // State 1: Sedang memuat data dari server
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              // State 2: Terjadi error saat request data
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(_errorMsg!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchAnggota, 
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _anggotaList.isEmpty
                  // State 3: Sukses terhubung tapi data anggota masih kosong
                  ? const Center(child: Text('Belum ada anggota.', style: TextStyle(fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _fetchAnggota, // Fitur tarik ke bawah untuk refresh data
                      
                      // Cek jika hasil filter kosong (misal kata kunci pencarian tidak cocok)
                      child: displayList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('Tidak ada hasil pencarian.', style: TextStyle(fontSize: 16)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                final a = displayList[index];
                                
                                // ─── CARD SETIAP ANGGOTA ───
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    // Avatar lingkaran dengan inisial nama huruf pertama kapital
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.deepPurple, // UBAH WARNA AVATAR DI SINI
                                      child: Text(
                                        a.nama.isNotEmpty ? a.nama[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(a.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('No. Induk: ${a.nomorInduk}'),
                                        const SizedBox(height: 2),
                                        
                                        // Baris indikator status aktif (Aktif = Hijau, Tidak Aktif = Abu-abu)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 10,
                                              color: a.statusAktif == 1 ? Colors.green : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              a.statusAktif == 1 ? 'Aktif' : 'Tidak Aktif',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: a.statusAktif == 1 ? Colors.green : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                    
                                    // Aksi saat Card Anggota di-klik
                                    onTap: () {
                                      // Membuka halaman Tabungan anggota dengan membawa parameter ID & Nama
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TabunganPage(
                                            anggotaId: a.id,
                                            anggotaNama: a.nama,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
    );
  }
}
