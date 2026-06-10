class AnggotaModel {
  final int id;
  final int nomorInduk;
  final String nama;
  final String alamat;
  final String tglLahir;
  final String telepon;
  final String? imageUrl;
  final int statusAktif;

  AnggotaModel({
    required this.id,
    required this.nomorInduk,
    required this.nama,
    required this.alamat,
    required this.tglLahir,
    required this.telepon,
    this.imageUrl,
    required this.statusAktif,
  });

  /// Factory dari JSON response API
  /// Menggunakan safe parsing untuk handle tipe data yang bervariasi
  factory AnggotaModel.fromJson(Map<String, dynamic> json) {
    return AnggotaModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nomorInduk: int.tryParse(json['nomor_induk'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      tglLahir: json['tgl_lahir']?.toString() ?? '',
      telepon: json['telepon']?.toString() ?? '',
      imageUrl: json['photo_url']?.toString(),
      statusAktif: int.tryParse(json['status_aktif'].toString()) ?? 0,
    );
  }
}
