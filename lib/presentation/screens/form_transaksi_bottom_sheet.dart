import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/jenis_transaksi_model.dart';
import '../../data/services/tabungan_service.dart';

/// Bottom sheet untuk menambah transaksi baru — POST /api/tabungan.
/// Tampil melayang dari bawah layar untuk menerima input jenis transaksi dan nominal.
class FormTransaksiBottomSheet extends StatefulWidget {
  final int anggotaId;
  // List jenis transaksi yang diterima dari halaman pemanggil (TabunganPage)
  final List<JenisTransaksiModel> jenisTransaksi;
  // Callback ketika transaksi berhasil ditambahkan agar parent page me-refresh data
  final VoidCallback onSuccess;

  const FormTransaksiBottomSheet({
    super.key,
    required this.anggotaId,
    required this.jenisTransaksi,
    required this.onSuccess,
  });

  @override
  State<FormTransaksiBottomSheet> createState() => _FormTransaksiBottomSheetState();
}

class _FormTransaksiBottomSheetState extends State<FormTransaksiBottomSheet> {
  // ─── SERVICES & CONTROLLERS ───
  final _tabunganService = TabunganService();
  // Controller untuk membaca input nominal uang
  final _nominalController = TextEditingController();
  
  // ─── STATE VARIABLES ───
  // Menyimpan ID jenis transaksi yang dipilih dari dropdown (misal: Simpanan, Penarikan, dll)
  int? _selectedTrxId;
  // Status loading tombol simpan
  bool _isLoading = false;

  @override
  void dispose() {
    // Selalu dispose controller untuk mencegah kebocoran memori (memory leak)
    _nominalController.dispose();
    super.dispose();
  }

  // ─── METHOD SUBMIT DATA TRANSAKSI ───
  Future<void> _submit() async {
    // 1. Validasi: pastikan jenis transaksi sudah dipilih
    if (_selectedTrxId == null) {
      _showError('Pilih jenis transaksi terlebih dahulu.');
      return;
    }

    // 2. Validasi: pastikan nominal tidak kosong
    final nominal = _nominalController.text.trim();
    if (nominal.isEmpty) {
      _showError('Nominal wajib diisi.');
      return;
    }

    // 3. Validasi: pastikan nominal adalah angka positif > 0
    if (double.tryParse(nominal) == null || double.parse(nominal) <= 0) {
      _showError('Nominal harus berupa angka positif.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mengirim request transaksi baru ke server
      await _tabunganService.tambahTransaksi(
        anggotaId: widget.anggotaId,
        trxId: _selectedTrxId!,
        nominal: nominal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Tutup bottom sheet
        widget.onSuccess(); // Jalankan callback refresh data di halaman utama
      }
    } on TimeoutException {
      _showError('Koneksi timeout.');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Menampilkan pesan error sederhana menggunakan SnackBar
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Mengatur padding agar bottom sheet terdorong ke atas saat keyboard virtual HP muncul
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── DEKORASI HANDLE BAR DI BAGIAN ATAS SHEET ───
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Tambah Transaksi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ─── DROPDOWN: PILIH JENIS TRANSAKSI ───
          DropdownButtonFormField<int>(
            initialValue: _selectedTrxId,
            decoration: const InputDecoration(
              labelText: 'Jenis Transaksi',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            // Mengubah list model jenis transaksi menjadi item Dropdown
            items: widget.jenisTransaksi.map((jenis) {
              // Memberikan tanda panah kebawah (↓) untuk transaksi positif dan panah keatas (↑) untuk negatif
              final icon = jenis.multiplier >= 0 ? '↓' : '↑';
              return DropdownMenuItem(
                value: jenis.id,
                child: Text('$icon ${jenis.namaTrx}'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedTrxId = val),
          ),
          const SizedBox(height: 16),

          // ─── TEXTFIELD: NOMINAL TRANSAKSI ───
          TextFormField(
            controller: _nominalController,
            decoration: const InputDecoration(
              labelText: 'Nominal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
              hintText: 'Contoh: 500000',
            ),
            keyboardType: TextInputType.number, // Menampilkan keyboard angka di HP
          ),
          const SizedBox(height: 24),

          // ─── BUTTON: SIMPAN TRANSAKSI ───
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('SIMPAN TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
