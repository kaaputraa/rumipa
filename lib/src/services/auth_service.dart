import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  /// Sign up a user with email & password, then insert user profile into public.users
  Future<void> signUpAndCreateProfile({
    required String email,
    required String password,
    required String name,
    required String nim,
    required String phone,
    required String ktmPath,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      final err = response.error;
      throw Exception(err?.message ?? 'Unknown signup error');
    }

    final user = response.user!;

    // Insert profile into public.users. This call must satisfy your RLS policies.
    final insert = await _client.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'nim': nim,
      'phone': phone,
      'ktm_path': ktmPath,
      'role': 'user',
      'status': 'pending',
    });

    if (insert.error != null) {
      // Optional: rollback signup by deleting the auth user if profile insert failed.
      await _client.auth.api.deleteUser(
        user.id,
      ); // requires service_role in backend; will fail client-side
      throw Exception(insert.error!.message);
    }
  }
}
