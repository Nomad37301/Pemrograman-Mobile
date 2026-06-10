import 'package:flutter/material.dart';
import '../../data/models/anggota_model.dart';
import '../../data/services/anggota_service.dart';
import 'anggota_detail_page.dart';
import 'anggota_form_page.dart';

/// Halaman list anggota — GET /api/anggota
/// Fitur: search, pull-to-refresh, CRUD actions
class AnggotaListPage extends StatefulWidget {
  const AnggotaListPage({super.key});

  @override
  State<AnggotaListPage> createState() => _AnggotaListPageState();
}

class _AnggotaListPageState extends State<AnggotaListPage> {
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

  Future<void> _deleteAnggota(int id) async {
    try {
      await _anggotaService.deleteAnggota(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggota berhasil dihapus'), backgroundColor: Colors.green),
        );
      }
      _fetchAnggota();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _confirmDelete(int id, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Anggota'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAnggota(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Anggota', style: TextStyle(color: Colors.white)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnggotaFormPage()),
          );
          if (result == true) _fetchAnggota();
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                                    subtitle: Text('No. Induk: ${a.nomorInduk}'),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'detail') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => AnggotaDetailPage(anggotaId: a.id)),
                                          );
                                        } else if (val == 'edit') {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => AnggotaFormPage(anggotaId: a.id)),
                                          );
                                          if (result == true) _fetchAnggota();
                                        } else if (val == 'delete') {
                                          _confirmDelete(a.id, a.nama);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'detail', child: Text('Lihat Detail')),
                                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => AnggotaDetailPage(anggotaId: a.id)),
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
