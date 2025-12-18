// rumipa3/lib/src/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // Fungsi Signup (Tetap)
  Future<void> signUpAndCreateProfile({
    required String email,
    required String password,
    required String name,
    required String nim,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception('Signup failed');

      await _client.from('users').insert({
        'id': user.id,
        'name': name,
        'email': email,
        'nim': nim,
        'role': 'user',
        'status': 'pending',
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// UPDATE: Mengirim email reset dengan redirectTo
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        // Alamat redirect ini harus didaftarkan di Dashboard Supabase -> Authentication -> Redirect URLs
        redirectTo: 'io.supabase.flutter.rumipa3://reset-password',
      );
    } catch (e) {
      throw Exception('Gagal mengirimkan email reset: $e');
    }
  }

  /// FUNGSI BARU: Untuk memperbarui password setelah user masuk via link
  Future<void> updateNewPassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('Gagal memperbarui password: $e');
    }
  }
}
