# 📚 Dokumentasi API — Flutter `pemrograman-mobile`

> Dokumentasi ini merangkum seluruh pola penggunaan API dari project Flutter `login_page` (pemrograman-mobile).  
> Cocok di-copy sebagai referensi implementasi di project lain.

---

## 🗂️ Struktur Folder

```
lib/
├── main.dart
├── core/
│   └── constants/
│       └── app_colors.dart          # Konstanta warna & gradient global
└── features/
    ├── auth/
    │   ├── models/
    │   │   ├── user_model.dart
    │   │   ├── anggota_model.dart
    │   │   ├── tabungan_model.dart
    │   │   ├── jenis_transaksi_model.dart
    │   │   └── setting_bunga_model.dart
    │   ├── screens/                 # UI Pages
    │   │   ├── login_page.dart
    │   │   ├── signup_page.dart
    │   │   ├── anggota_page.dart
    │   │   ├── detail_anggota_page.dart
    │   │   ├── form_anggota_page.dart
    │   │   ├── form_transaksi_bottom_sheet.dart
    │   │   ├── setting_bunga_page.dart
    │   │   └── transaksi_tabungan_page.dart
    │   └── services/
    │       ├── auth_service.dart
    │       ├── anggota_service.dart
    │       ├── bunga_service.dart
    │       └── tabungan_service.dart
    └── home/
        └── screens/
            └── home_page.dart
```

---

## 📦 Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^8.0.2
  http: ^1.2.0                        # HTTP client untuk request API
  flutter_secure_storage: ^9.0.0      # Simpan token secara aman di device
  intl: ^0.20.2                       # Format tanggal & angka
  image_picker: ^1.2.2                # Pilih foto dari galeri/kamera
```

---

## 🌐 Base URL & Konfigurasi

```dart
// lib/features/auth/services/auth_service.dart
static const String baseUrl = 'https://mobileapis.manpits.xyz/api';
```

> Semua service lain menggunakan `AuthService.baseUrl` sebagai referensi agar mudah diganti.

---

## 🔑 Manajemen Token (`flutter_secure_storage`)

Token disimpan secara aman menggunakan `flutter_secure_storage` dengan key `"auth_token"`.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final FlutterSecureStorage _storage = const FlutterSecureStorage();
final String _tokenKey = "auth_token";

// Simpan token
await _storage.write(key: _tokenKey, value: token);

// Baca token
final String? token = await _storage.read(key: _tokenKey);

// Hapus token (logout)
await _storage.delete(key: _tokenKey);
```

**Pola mendapatkan token di service:**
```dart
final token = await _authService.getToken();
if (token == null) throw Exception('Sesi habis.');
```

---

## 📋 Header Request

### Header untuk JSON request:
```dart
{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer $token',
}
```

### Header untuk Multipart/Form-data request:
```dart
{
  'Accept': 'application/json',
  'Authorization': 'Bearer $token',
  // JANGAN sertakan 'Content-Type' — diset otomatis oleh MultipartRequest
}
```

---

## 🔐 Auth Service — `AuthService`

File: `lib/features/auth/services/auth_service.dart`

### 1. Register

```dart
// POST /api/register
// Body: JSON
// Auth: TIDAK diperlukan

await AuthService().register(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'secret123',
  passwordConfirmation: 'secret123',
);
```

**Request Body (JSON):**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "secret123",
  "password_confirmation": "secret123"
}
```

---

### 2. Login

```dart
// POST /api/login
// Body: JSON
// Auth: TIDAK diperlukan
// Side effect: Menyimpan token ke secure storage secara otomatis

await AuthService().login(
  email: 'john@example.com',
  password: 'secret123',
);
```

**Request Body (JSON):**
```json
{
  "email": "john@example.com",
  "password": "secret123"
}
```

**Response sukses yang diharapkan:**
```json
{
  "data": {
    "token": "Bearer_token_string_here"
  }
}
```

---

### 3. Get User (Profil)

```dart
// GET /api/user
// Auth: Bearer Token

final UserModel user = await AuthService().getUser();
print(user.name);   // String
print(user.email);  // String
print(user.id);     // int
```

**Response JSON (nested):**
```json
{
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    "expired": "2025-01-01 00:00:00"
  }
}
```

---

### 4. Logout

```dart
// GET /api/logout
// Auth: Bearer Token
// Side effect: Menghapus token dari secure storage

await AuthService().logout();
```

> ⚠️ Error jaringan saat logout sengaja **diabaikan** — token lokal tetap terhapus agar user bisa keluar.

---

### Helper: `_handleResponse` — Error Handling HTTP

```dart
// Pattern error handling yang digunakan di auth_service
// Sudah menangani: 200-299 (sukses), 400, 401, 405, 422, dan error lainnya

Map<String, dynamic> _handleResponse(http.Response response) {
  Map<String, dynamic> responseBody;
  try {
    responseBody = jsonDecode(response.body);
  } catch (e) {
    throw Exception('Server mengembalikan format yang tidak dikenali (${response.statusCode})');
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return responseBody;
  } else if (response.statusCode == 401 || response.statusCode == 405) {
    throw Exception('Email atau Password salah! Silakan coba lagi.');
  } else if (response.statusCode == 400) {
    throw Exception(responseBody['message'] ?? 'Permintaan tidak valid.');
  } else if (response.statusCode == 422) {
    final errors = responseBody['errors'];
    if (errors != null) {
      throw Exception(errors.values.first[0]);
    }
    throw Exception('Data yang dimasukkan tidak valid.');
  } else {
    throw Exception('Terjadi kesalahan server (${response.statusCode}).');
  }
}
```

---

## 👤 Anggota Service — `AnggotaService`

File: `lib/features/auth/services/anggota_service.dart`

### 1. Get All Anggota (Index)

```dart
// GET /api/anggota
// Auth: Bearer Token

final List<AnggotaModel> list = await AnggotaService().getAnggotas();
```

**Response JSON:**
```json
{
  "data": {
    "anggotas": [
      {
        "id": 1,
        "nomor_induk": 1001,
        "nama": "Budi Santoso",
        "alamat": "Jl. Mawar No. 5",
        "tgl_lahir": "1995-03-15",
        "telepon": "081234567890",
        "photo_url": "https://...",
        "status_aktif": 1
      }
    ]
  }
}
```

---

### 2. Create Anggota (dengan upload foto)

```dart
// POST /api/anggota
// Content-Type: multipart/form-data
// Auth: Bearer Token

import 'package:image_picker/image_picker.dart';

final XFile? imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);

await AnggotaService().createAnggota(
  {
    'nomor_induk': '1002',
    'nama': 'Siti Rahayu',
    'alamat': 'Jl. Melati No. 3',
    'tgl_lahir': '1998-07-20',
    'telepon': '089876543210',
    'status_aktif': '1',
  },
  imageFile: imageFile, // opsional
);
```

**Form Fields:**
| Field | Tipe | Keterangan |
|-------|------|------------|
| `nomor_induk` | String | Nomor induk anggota |
| `nama` | String | Nama lengkap |
| `alamat` | String | Alamat |
| `tgl_lahir` | String | Format `YYYY-MM-DD` |
| `telepon` | String | Nomor telepon |
| `status_aktif` | String (`"0"` / `"1"`) | Status aktif |
| `photo` | File (opsional) | File gambar |

---

### 3. Get Anggota by ID (Show)

```dart
// GET /api/anggota/{id}
// Auth: Bearer Token

final AnggotaModel anggota = await AnggotaService().getAnggotaById(1);
```

**Response JSON:**
```json
{
  "data": {
    "id": 1,
    "nomor_induk": 1001,
    "nama": "Budi Santoso",
    ...
  }
}
```

---

### 4. Update Anggota (dengan upload foto)

```dart
// POST /api/anggota/{id}  (dengan _method: PUT via form-data)
// Content-Type: multipart/form-data
// Auth: Bearer Token

await AnggotaService().updateAnggota(
  1, // id anggota
  {
    'nama': 'Budi Santoso Updated',
    'telepon': '082111222333',
    // ... field lain yang ingin diupdate
  },
  imageFile: imageFile, // opsional
);
```

> 💡 **Catatan penting:** Update menggunakan `POST` dengan tambahan field `_method: PUT` (Laravel method spoofing), bukan `PUT` langsung. Ini karena multipart/form-data tidak mendukung method `PUT` secara native.

---

### 5. Delete Anggota

```dart
// DELETE /api/anggota/{id}
// Auth: Bearer Token

await AnggotaService().deleteAnggota(1);
```

---

## 💰 Tabungan Service — `TabunganService`

File: `lib/features/auth/services/tabungan_service.dart`

### 1. Get Jenis Transaksi

```dart
// GET /api/jenistransaksi
// Auth: Bearer Token

final List<JenisTransaksiModel> jenis = await TabunganService().getJenisTransaksi();
```

**Response JSON:**
```json
{
  "data": {
    "jenistransaksi": [
      { "id": 1, "trx_name": "Saldo Awal", "trx_multiply": 1 },
      { "id": 2, "trx_name": "Simpanan", "trx_multiply": 1 },
      { "id": 3, "trx_name": "Penarikan", "trx_multiply": -1 }
    ]
  }
}
```

> `trx_multiply`: `1` = menambah saldo, `-1` = mengurangi saldo.

---

### 2. Get Detail Tabungan (Saldo + Riwayat)

```dart
// GET /api/saldo/{anggota_id}   ─┐ dijalankan
// GET /api/tabungan/{anggota_id} ─┘ paralel (Future.wait)
// Auth: Bearer Token

final Map<String, dynamic> detail = await TabunganService().getDetailTabungan(anggotaId);

final double saldo = detail['saldo'];                 // double
final List<TabunganModel> riwayat = detail['riwayat']; // List<TabunganModel>
```

**Pola Parallel Request:**
```dart
// Dua request dijalankan bersamaan menggunakan Future.wait
final responses = await Future.wait([saldoFuture, riwayatFuture]);
```

**Response `/api/saldo/{id}`:**
```json
{
  "data": {
    "saldo": "1500000.00"
  }
}
```

**Response `/api/tabungan/{id}`:**
```json
{
  "data": {
    "tabungan": [
      {
        "id": 1,
        "anggota_id": 5,
        "trx_id": 2,
        "trx_nominal": "500000.00",
        "trx_tanggal": "2024-01-15"
      }
    ]
  }
}
```

---

### 3. Tambah Transaksi

```dart
// POST /api/tabungan
// Content-Type: multipart/form-data
// Auth: Bearer Token

await TabunganService().tambahTransaksi(
  anggotaId: 5,
  trxId: 2,        // ID dari JenisTransaksiModel
  nominal: '500000',
);
```

**Form Fields:**
| Field | Tipe | Keterangan |
|-------|------|------------|
| `anggota_id` | String | ID anggota |
| `trx_id` | String | ID jenis transaksi |
| `trx_nominal` | String | Nominal transaksi |

---

## 📈 Bunga Service — `BungaService`

File: `lib/features/auth/services/bunga_service.dart`

### 1. Get Setting Bunga (Aktif + Riwayat)

```dart
// GET /api/settingbunga
// Auth: Bearer Token

final Map<String, dynamic> result = await BungaService().getSettingBunga();

final SettingBungaModel? active = result['active'];           // bisa null
final List<SettingBungaModel> history = result['history'];    // List
```

**Response JSON:**
```json
{
  "data": {
    "activebunga": {
      "id": 3,
      "persen": "2.5",
      "isaktif": 1
    },
    "settingbungas": [
      { "id": 1, "persen": "1.5", "isaktif": 0 },
      { "id": 2, "persen": "2.0", "isaktif": 0 }
    ]
  }
}
```

---

### 2. Add Setting Bunga

```dart
// POST /api/addsettingbunga
// Content-Type: multipart/form-data
// Auth: Bearer Token

await BungaService().addSettingBunga(
  persen: '3.0',
  isAktif: 1,    // 1 = aktif, 0 = tidak aktif
);
```

**Form Fields:**
| Field | Tipe | Keterangan |
|-------|------|------------|
| `persen` | String | Persentase bunga |
| `isaktif` | String (`"0"` / `"1"`) | Status aktif bunga |

---

## 🗃️ Data Models

### `UserModel`
```dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? expired;
}
```

### `AnggotaModel`
```dart
class AnggotaModel {
  final int id;
  final int nomorInduk;    // dari JSON: 'nomor_induk'
  final String nama;
  final String alamat;
  final String tglLahir;   // dari JSON: 'tgl_lahir'
  final String telepon;
  final String? imageUrl;  // dari JSON: 'photo_url'
  final int statusAktif;   // dari JSON: 'status_aktif'
}
```

### `TabunganModel`
```dart
class TabunganModel {
  final int id;
  final int anggotaId;   // dari JSON: 'anggota_id'
  final int trxId;       // dari JSON: 'trx_id'
  final double nominal;  // dari JSON: 'trx_nominal'
  final String tanggal;  // dari JSON: 'trx_tanggal'
}
```

### `JenisTransaksiModel`
```dart
class JenisTransaksiModel {
  final int id;
  final String namaTrx;   // dari JSON: 'trx_name'
  final int multiplier;   // dari JSON: 'trx_multiply' (1 atau -1)
}
```

### `SettingBungaModel`
```dart
class SettingBungaModel {
  final int id;
  final double persen;   // dari JSON: 'persen'
  final int isAktif;     // dari JSON: 'isaktif'
}
```

---

## 🗺️ Ringkasan Semua Endpoint API

| Method | Endpoint | Auth | Content-Type | Keterangan |
|--------|----------|------|-------------|------------|
| `POST` | `/api/register` | ❌ | JSON | Daftar akun baru |
| `POST` | `/api/login` | ❌ | JSON | Login, simpan token |
| `GET` | `/api/user` | ✅ | - | Ambil profil user |
| `GET` | `/api/logout` | ✅ | - | Logout, hapus token |
| `GET` | `/api/anggota` | ✅ | - | List semua anggota |
| `POST` | `/api/anggota` | ✅ | form-data | Tambah anggota (+ foto) |
| `GET` | `/api/anggota/{id}` | ✅ | - | Detail anggota |
| `POST` | `/api/anggota/{id}` | ✅ | form-data | Update anggota (`_method: PUT`) |
| `DELETE` | `/api/anggota/{id}` | ✅ | - | Hapus anggota |
| `GET` | `/api/jenistransaksi` | ✅ | - | List jenis transaksi |
| `GET` | `/api/saldo/{anggota_id}` | ✅ | - | Saldo anggota |
| `GET` | `/api/tabungan/{anggota_id}` | ✅ | - | Riwayat tabungan |
| `POST` | `/api/tabungan` | ✅ | form-data | Tambah transaksi |
| `GET` | `/api/settingbunga` | ✅ | - | Setting bunga aktif + riwayat |
| `POST` | `/api/addsettingbunga` | ✅ | form-data | Tambah setting bunga baru |

---

## 💡 Pola Penting & Best Practices

### 1. Timeout pada Request Kritis
```dart
await http.post(Uri.parse('$baseUrl/login'), ...).timeout(const Duration(seconds: 10));
```

### 2. Handle SocketException (Tidak ada internet)
```dart
try {
  // ... request
} on SocketException {
  throw Exception('Tidak ada koneksi internet.');
} catch (e) {
  throw Exception('Error: $e');
}
```

### 3. Upload File dengan MultipartRequest
```dart
var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/endpoint'));
request.headers.addAll({ 'Authorization': 'Bearer $token' });
request.fields['field_name'] = 'value';

// Tambah file
final bytes = await imageFile.readAsBytes();
request.files.add(http.MultipartFile.fromBytes(
  'photo',      // nama field di server
  bytes,
  filename: imageFile.name,
));

final response = await request.send();
// Untuk baca response body:
final responseData = await http.Response.fromStream(response);
```

### 4. Laravel Method Spoofing untuk PUT
```dart
// Saat update dengan form-data, gunakan POST + _method: PUT
var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/resource/$id'));
request.fields['_method'] = 'PUT';
```

### 5. Parallel Request dengan Future.wait
```dart
final results = await Future.wait([
  http.get(Uri.parse('$baseUrl/saldo/$id'), headers: headers),
  http.get(Uri.parse('$baseUrl/tabungan/$id'), headers: headers),
]);
final saldoRes = results[0];
final riwayatRes = results[1];
```

### 6. Konversi Aman (Safe Parsing)
```dart
// Gunakan tryParse untuk angka dari API yang mungkin datang sebagai String atau int
nomorInduk: int.tryParse(json['nomor_induk'].toString()) ?? 0,
nominal: double.tryParse(json['trx_nominal'].toString()) ?? 0.0,
```
