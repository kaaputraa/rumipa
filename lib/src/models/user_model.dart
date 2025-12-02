class UserModel {
  final String id;
  final String name;
  final String email;
  final String nim;
  final String phone;
  final String ktmPath;
  final String role;
  final String status;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nim,
    required this.phone,
    required this.ktmPath,
    required this.role,
    required this.status,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'],
    name: m['name'],
    email: m['email'],
    nim: m['nim'],
    phone: m['phone'],
    ktmPath: m['ktm_path'] ?? '',
    role: m['role'] ?? 'user',
    status: m['status'] ?? 'pending',
  );
}
