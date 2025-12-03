// rumipa3/lib/src/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  Future<void> signUpAndCreateProfile({
    required String email,
    required String password,
    required String name,
    required String nim,
    // required String phone, Dihapus
    // required String ktmPath, Dihapus
  }) async {
    try {
      // Sign up user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Signup failed: no user returned');
      }

      // Insert profile
      final insertResult = await _client.from('users').insert({
        'id': user.id,
        'name': name,
        'email': email,
        'nim': nim,
        // 'phone': phone, Dihapus
        // 'ktm_path': ktmPath, Dihapus
        'role': 'user',
        'status': 'pending',
      });

      if (insertResult.error != null) {
        throw Exception(insertResult.error!.message);
      }
    } on AuthException catch (e) {
      // Error dari auth (email sudah dipakai, password kurang kuat, dll)
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
