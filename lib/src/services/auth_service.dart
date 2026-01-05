// rumipa3/lib/src/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // Fungsi Signup (Tetap)
  Future<void> signUpAndCreateProfile({
    required String email,
    required String password,
    required String name, // Data ini akan dikirim ke Metadata
    required String nim, // Data ini akan dikirim ke Metadata
  }) async {
    try {
      // 1. Daftar ke Supabase Auth & Kirim Metadata
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, // Metadata ditangkap oleh Trigger SQL
          'nim': nim, // Metadata ditangkap oleh Trigger SQL
        },
        // URL ini harus cocok dengan yang didaftarkan di Dashboard
        emailRedirectTo: 'io.supabase.flutter.rumipa3://login-callback',
      );

      // 2. HAPUS kode manual insert ke tabel 'users'.
      // JANGAN ADA KODE: await _client.from('users').insert(...)
      // Biarkan Trigger database yang bekerja.
    } catch (e) {
      throw Exception(e.toString()); // Lempar error ke UI jika gagal
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
