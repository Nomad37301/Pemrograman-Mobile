import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import 'login_page.dart';
import 'anggota_list_page.dart';
import 'setting_bunga_page.dart';
import 'transaksi_tabungan_page.dart';

/// Halaman utama (Dashboard) — menampilkan profil user yang login dan menu navigasi utama
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ─── INSTANCE SERVICES ───
  // Service untuk urusan autentikasi (get profile, logout, dll)
  final _authService = AuthService();
  
  // ─── STATE VARIABLES ───
  // Menyimpan data profile user yang login (ID, Nama, Email)
  UserModel? _user;
  // Loading status saat memanggil profile dari server
  bool _isLoadingProfile = true;
  // Loading status saat proses logout berjalan
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Panggil API profile user saat dashboard pertama kali dibuka
    _fetchUserProfile();
  }

  // ─── METHOD REQUEST API PROFILE ───
  Future<void> _fetchUserProfile() async {
    try {
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR FETCH PROFILE: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  // ─── METHOD LOGOUT ───
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    
    // Memanggil API logout (menghapus token di server dan secure storage lokal)
    await _authService.logout();

    if (mounted) {
      // Mengarahkan user kembali ke halaman Login dan membersihkan stack halaman sebelumnya
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // ─── DIALOG KONFIRMASI LOGOUT ───
  // Menampilkan pop-up dialog peringatan sebelum user keluar dari aplikasi
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          // Tombol Batal
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          // Tombol Konfirmasi Logout (Warna Merah)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              _logout(); // Panggil method logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil Nama dan Email user yang berhasil di-load dari API (Default: 'User')
    final userName = _user?.name ?? 'User';
    final userEmail = _user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple, // UBAH WARNA APPBAR DI SINI
        automaticallyImplyLeading: false, // Menghilangkan tombol back default di home screen
        actions: [
          // Tombol logout di bagian kanan AppBar
          IconButton(
            onPressed: _isLoggingOut ? null : _showLogoutDialog,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      
      // ─── BODY UTAMA DASHBOARD ───
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ─── WIDGET 1: KARTU SELAMAT DATANG (WELCOME CARD WITH GRADIENT) ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      // Menggunakan dekorasi warna gradasi agar tampak premium
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.purpleAccent], // UBAH WARNA GRADASI DI SINI
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
                          'Selamat Datang! 👋',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(userName, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                        if (userEmail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(userEmail, style: const TextStyle(fontSize: 14, color: Colors.white60)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── WIDGET 2: SEKSI DETAIL INFORMASI USER ───
                  const Text('Informasi Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.deepPurple),
                      title: const Text('Nama'),
                      subtitle: Text(userName),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.email, color: Colors.deepPurple),
                      title: const Text('Email'),
                      subtitle: Text(userEmail.isNotEmpty ? userEmail : '-'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── WIDGET 3: SEKSI NAVIGASI MENU UTAMA ───
                  const Text('Menu Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // MENU 1: KELOLA ANGGOTA
                  Card(
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.group, color: Colors.deepPurple),
                      title: const Text('Kelola Anggota', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Daftar anggota, tambah anggota baru, edit, dan hapus'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Membuka halaman list kelola anggota
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnggotaListPage()));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // MENU 2: TRANSAKSI TABUNGAN (YANG BARU DIPISAH)
                  Card(
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
                      title: const Text('Transaksi Tabungan', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Kelola simpanan, penarikan, dan cek saldo anggota'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Membuka halaman list transaksi tabungan (pilih anggota dulu)
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransaksiTabunganPage()));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // MENU 3: SETTING BUNGA
                  Card(
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.percent, color: Colors.deepPurple),
                      title: const Text('Setting Bunga', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Atur persentase bunga tabungan koperasi'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Membuka halaman pengatur setting bunga
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingBungaPage()));
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── WIDGET 4: TOMBOL KELUAR DI BAWAH MENU ───
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoggingOut ? null : _showLogoutDialog,
                      icon: _isLoggingOut
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.logout),
                      label: Text(_isLoggingOut ? 'Logging out...' : 'LOGOUT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Tombol Logout berwarna merah
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
