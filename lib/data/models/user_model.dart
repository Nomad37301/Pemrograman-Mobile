class UserModel {
  final int id;
  final String name;
  final String email;
  final String? expired;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.expired,
  });

  /// Factory dari JSON response API
  /// Response: { "data": { "user": { ... }, "expired": "..." } }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      expired: json['expired']?.toString(),
    );
  }
}
