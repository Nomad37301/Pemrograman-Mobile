import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/jenis_transaksi_model.dart';
import '../../data/services/tabungan_service.dart';

/// Bottom sheet untuk menambah transaksi baru — POST /api/tabungan
class FormTransaksiBottomSheet extends StatefulWidget {
  final int anggotaId;
  final List<JenisTransaksiModel> jenisTransaksi;
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
  final _tabunganService = TabunganService();
  final _nominalController = TextEditingController();
  int? _selectedTrxId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedTrxId == null) {
      _showError('Pilih jenis transaksi terlebih dahulu.');
      return;
    }

    final nominal = _nominalController.text.trim();
    if (nominal.isEmpty) {
      _showError('Nominal wajib diisi.');
      return;
    }

    if (double.tryParse(nominal) == null || double.parse(nominal) <= 0) {
      _showError('Nominal harus berupa angka positif.');
      return;
    }

    setState(() => _isLoading = true);

    try {
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
        Navigator.pop(context);
        widget.onSuccess();
      }
    } on TimeoutException {
      _showError('Koneksi timeout.');
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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

          // Dropdown jenis transaksi
          DropdownButtonFormField<int>(
            initialValue: _selectedTrxId,
            decoration: const InputDecoration(
              labelText: 'Jenis Transaksi',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: widget.jenisTransaksi.map((jenis) {
              final icon = jenis.multiplier >= 0 ? '↓' : '↑';
              return DropdownMenuItem(
                value: jenis.id,
                child: Text('$icon ${jenis.namaTrx}'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedTrxId = val),
          ),
          const SizedBox(height: 16),

          // Input nominal
          TextFormField(
            controller: _nominalController,
            decoration: const InputDecoration(
              labelText: 'Nominal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
              hintText: 'Contoh: 500000',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Tombol submit
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
