class SettingBungaModel {
  final int id;
  final double persen;
  final int isAktif; // 1 = aktif, 0 = tidak aktif

  SettingBungaModel({
    required this.id,
    required this.persen,
    required this.isAktif,
  });

  factory SettingBungaModel.fromJson(Map<String, dynamic> json) {
    return SettingBungaModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      persen: double.tryParse(json['persen'].toString()) ?? 0.0,
      isAktif: int.tryParse(json['isaktif'].toString()) ?? 0,
    );
  }
}
