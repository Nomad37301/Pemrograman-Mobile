class TabunganModel {
  final int id;
  final int anggotaId;
  final int trxId;
  final double nominal;
  final String tanggal;

  TabunganModel({
    required this.id,
    required this.anggotaId,
    required this.trxId,
    required this.nominal,
    required this.tanggal,
  });

  /// Factory dari JSON response API
  /// nominal (trx_nominal) bisa berupa String "500000.00" → parse ke double
  factory TabunganModel.fromJson(Map<String, dynamic> json) {
    return TabunganModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      anggotaId: int.tryParse(json['anggota_id'].toString()) ?? 0,
      trxId: int.tryParse(json['trx_id'].toString()) ?? 0,
      nominal: double.tryParse(json['trx_nominal'].toString()) ?? 0.0,
      tanggal: json['trx_tanggal']?.toString() ?? '',
    );
  }
}
