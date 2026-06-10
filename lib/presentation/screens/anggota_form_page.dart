import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../../data/services/anggota_service.dart';

/// Form untuk tambah / edit anggota
/// Jika anggotaId == null → mode tambah (POST /api/anggota)
/// Jika anggotaId != null → mode edit (POST /api/anggota/{id} + _method: PUT)
class AnggotaFormPage extends StatefulWidget {
  final int? anggotaId;
  const AnggotaFormPage({super.key, this.anggotaId});

  @override
  State<AnggotaFormPage> createState() => _AnggotaFormPageState();
}

class _AnggotaFormPageState extends State<AnggotaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _anggotaService = AnggotaService();

  final _nomorIndukCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _tglLahirCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  int _statusAktif = 1;

  bool _isLoading = false;
  bool _isFetchingDetail = false;
  XFile? _selectedImage;

  bool get _isEdit => widget.anggotaId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExistingData();
  }

  @override
  void dispose() {
    _nomorIndukCtrl.dispose();
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _tglLahirCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isFetchingDetail = true);
    try {
      final anggota = await _anggotaService.getAnggotaById(widget.anggotaId!);
      _nomorIndukCtrl.text = anggota.nomorInduk.toString();
      _namaCtrl.text = anggota.nama;
      _alamatCtrl.text = anggota.alamat;
      _tglLahirCtrl.text = anggota.tglLahir;
      _teleponCtrl.text = anggota.telepon;
      _statusAktif = anggota.statusAktif;
    } catch (e) {
      debugPrint('ERROR LOAD EDIT DATA: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
    if (mounted) setState(() => _isFetchingDetail = false);
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.tryParse(_tglLahirCtrl.text) ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _tglLahirCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final fields = {
        'nomor_induk': _nomorIndukCtrl.text.trim(),
        'nama': _namaCtrl.text.trim(),
        'alamat': _alamatCtrl.text.trim(),
        'tgl_lahir': _tglLahirCtrl.text.trim(),
        'telepon': _teleponCtrl.text.trim(),
        'status_aktif': _statusAktif.toString(),
      };

      if (_isEdit) {
        await _anggotaService.updateAnggota(
          widget.anggotaId!,
          fields,
          imageFile: _selectedImage,
        );
      } else {
        await _anggotaService.createAnggota(
          fields,
          imageFile: _selectedImage,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Anggota berhasil diupdate!' : 'Anggota berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on TimeoutException {
      _showError('Koneksi timeout. Coba lagi nanti.');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(_isEdit ? 'Edit Anggota' : 'Tambah Anggota', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isFetchingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Foto picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.deepPurple.shade100,
                        child: _selectedImage != null
                            ? const Icon(Icons.check_circle, size: 40, color: Colors.green)
                            : const Icon(Icons.camera_alt, size: 32, color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImage != null ? 'Foto dipilih' : 'Tap untuk pilih foto (opsional)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // Nomor Induk
                    TextFormField(
                      controller: _nomorIndukCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Induk',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Nama
                    TextFormField(
                      controller: _namaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Alamat
                    TextFormField(
                      controller: _alamatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Lahir
                    TextFormField(
                      controller: _tglLahirCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.cake),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                      ),
                      readOnly: true,
                      onTap: _pickDate,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Telepon
                    TextFormField(
                      controller: _teleponCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Status Aktif
                    DropdownButtonFormField<int>(
                      initialValue: _statusAktif,
                      decoration: const InputDecoration(
                        labelText: 'Status Aktif',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Aktif')),
                        DropdownMenuItem(value: 0, child: Text('Tidak Aktif')),
                      ],
                      onChanged: (v) => setState(() => _statusAktif = v ?? 1),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_isEdit ? Icons.save : Icons.add),
                        label: Text(
                          _isLoading
                              ? 'Menyimpan...'
                              : (_isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH ANGGOTA'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
