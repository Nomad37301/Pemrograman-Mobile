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
  final _anggotaService = AnggotaService();
  List<AnggotaModel> _anggotaList = [];
  bool _isLoading = true;
  String? _errorMsg;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    _fetchAnggota();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Tabungan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor induk...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
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
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(_errorMsg!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchAnggota, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _anggotaList.isEmpty
                  ? const Center(child: Text('Belum ada anggota.', style: TextStyle(fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _fetchAnggota,
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
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.deepPurple,
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
                                    onTap: () {
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
