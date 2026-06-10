class JenisTransaksiModel {
  final int id;
  final String namaTrx;
  final int multiplier; // 1 = menambah saldo, -1 = mengurangi saldo

  JenisTransaksiModel({
    required this.id,
    required this.namaTrx,
    required this.multiplier,
  });

  factory JenisTransaksiModel.fromJson(Map<String, dynamic> json) {
    return JenisTransaksiModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      namaTrx: json['trx_name']?.toString() ?? '',
      multiplier: int.tryParse(json['trx_multiply'].toString()) ?? 1,
    );
  }
}
