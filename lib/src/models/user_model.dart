class UserModel {
  final String id;
  final String name;
  final String email;
  final String nim;
  final String phone; // Dianggap non-nullable, tapi bisa NULL di DB
  final String ktmPath; // Dianggap non-nullable, tapi bisa NULL di DB
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
    // PERBAIKAN: Berikan nilai default '' (String kosong) jika NULL
    phone: m['phone'] ?? '',
    ktmPath: m['ktm_path'] ?? '',
    role: m['role'] ?? 'user',
    status: m['status'] ?? 'pending',
  );
}
