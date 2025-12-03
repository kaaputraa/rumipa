import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../screens/home/user_dashboard.dart';
import '../screens/home/admin_dashboard.dart';

class SessionHandler extends StatefulWidget {
  const SessionHandler({super.key});

  @override
  State<SessionHandler> createState() => _SessionHandlerState();
}

class _SessionHandlerState extends State<SessionHandler> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  Session? _session;
  String? _role;

  @override
  void initState() {
    super.initState();

    /// Ambil session awal
    _session = supabase.auth.currentSession;

    /// Dengarkan perubahan session (login/logout)
    supabase.auth.onAuthStateChange.listen((event) {
      setState(() {
        _session = event.session;
      });

      if (_session != null) {
        _loadUserRole();
      } else {
        setState(() {
          _role = null;
          _loading = false;
        });
      }
    });

    /// Jika sudah login saat app dibuka
    if (_session != null) {
      _loadUserRole();
    } else {
      _loading = false;
    }
  }

  /// ================================
  /// LOAD ROLE USER (+ auto insert)
  /// ================================
  Future<void> _loadUserRole() async {
    final uid = _session!.user.id;

    try {
      /// Coba ambil user berdasarkan ID
      final response = await supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      /// Jika user BELUM ADA → otomatis buat
      if (response == null) {
        // NOTE: Operasi INSERT ini akan gagal jika RLS INSERT belum diatur
        final insertRes = await supabase
            .from('users')
            .insert({
              'id': uid,
              'role': 'user', // default role untuk users baru
            })
            .select()
            .single();

        setState(() {
          _role = insertRes['role'];
          _loading = false;
        });
        return;
      }

      /// Jika user ada → ambil role
      setState(() {
        _role = response['role'];
        _loading = false;
      });
    } catch (e) {
      // Jika error RLS atau lainnya
      print("ERROR load role: $e");

      // PERBAIKAN: pastikan _loading diatur ke false setelah error
      setState(() => _loading = false);
    }
  }

  /// ================================
  /// UI HANDLING
  /// ================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Loading state pertama saat inisialisasi sesi atau memuat peran
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /// 1. Tidak ada session → ke LoginScreen
    if (_session == null) {
      return const LoginScreen();
    }

    /// 2. Role masih null (load role gagal)
    if (_role == null) {
      // PERBAIKAN: Jika ada sesi tapi peran gagal dimuat (misal RLS error)
      // Alihkan ke LoginScreen untuk mencegah infinite loading loop.
      return const LoginScreen();
    }

    /// 3. Jika admin
    if (_role == 'admin') {
      return const AdminDashboard();
    }

    /// 4. Default user
    return const UserDashboard();
  }
}
