import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final _client = Supabase.instance.client;

  /// Mengambil data profil pengguna saat ini
  Future<UserModel> fetchCurrentUserProfile() async {
    final uid = _client.auth.currentUser!.id;

    // Gunakan .select().single() yang langsung memfetch data terbaru
    final response = await _client
        .from('users')
        .select()
        .eq('id', uid)
        .single();

    return UserModel.fromMap(response);
  }

  /// Memperbarui kolom phone dan ktm_path
  Future<void> updateProfile({
    required String uid,
    required String phone,
    required String ktmPath,
  }) async {
    await _client
        .from('users')
        .update({
          'phone': phone,
          'ktm_path': ktmPath,
          // 'status' tidak diubah di sini, biarkan Admin yang memverifikasi dan mengubahnya
        })
        .eq('id', uid);
  }
}
