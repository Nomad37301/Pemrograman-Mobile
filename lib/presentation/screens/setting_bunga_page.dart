import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/setting_bunga_model.dart';
import '../../data/services/bunga_service.dart';

/// Halaman setting bunga — GET /api/settingbunga + POST /api/addsettingbunga
class SettingBungaPage extends StatefulWidget {
  const SettingBungaPage({super.key});

  @override
  State<SettingBungaPage> createState() => _SettingBungaPageState();
}

class _SettingBungaPageState extends State<SettingBungaPage> {
  final _bungaService = BungaService();

  SettingBungaModel? _activeBunga;
  List<SettingBungaModel> _historyBunga = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final result = await _bungaService.getSettingBunga();
      if (mounted) {
        setState(() {
          _activeBunga = result['active'] as SettingBungaModel?;
          _historyBunga = result['history'] as List<SettingBungaModel>;
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

  void _showAddBungaDialog() {
    final persenController = TextEditingController();
    int isAktif = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Setting Bunga'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: persenController,
                decoration: const InputDecoration(
                  labelText: 'Persentase Bunga (%)',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: 2.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: isAktif,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Aktif')),
                  DropdownMenuItem(value: 0, child: Text('Tidak Aktif')),
                ],
                onChanged: (v) => setDialogState(() => isAktif = v ?? 1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final persen = persenController.text.trim();
                if (persen.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Persentase wajib diisi.')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                await _addBunga(persen, isAktif);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBunga(String persen, int isAktif) async {
    try {
      await _bungaService.addSettingBunga(persen: persen, isAktif: isAktif);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setting bunga berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData(); // Refresh
    } on TimeoutException {
      _showError('Koneksi timeout.');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting Bunga', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBungaDialog,
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
                      // ─── Card Bunga Aktif ───
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent],
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
                              'Bunga Aktif Saat Ini',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _activeBunga != null ? '${_activeBunga!.persen}%' : 'Belum diatur',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── Riwayat Setting Bunga ───
                      const Text(
                        'Riwayat Setting Bunga',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (_historyBunga.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Belum ada riwayat.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ..._historyBunga.map((bunga) => Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: bunga.isAktif == 1
                                      ? Colors.green.shade50
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    Icons.percent,
                                    color: bunga.isAktif == 1 ? Colors.green : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  '${bunga.persen}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('ID: ${bunga.id}'),
                                trailing: bunga.isAktif == 1
                                    ? const Chip(
                                        label: Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        backgroundColor: Colors.green,
                                      )
                                    : const Text('Tidak Aktif', style: TextStyle(color: Colors.grey)),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}
