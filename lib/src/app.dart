import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../src/screens/auth/login_screen.dart';
import '../src/screens/home/user_dashboard.dart';
import '../src/screens/home/admin_dashboard.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SessionHandler(),
    );
  }
}

class SessionHandler extends StatefulWidget {
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

    // Ambil session awal
    _session = supabase.auth.currentSession;

    // dengarkan perubahan session
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _session = data.session;
      });

      if (_session != null) {
        _loadUserRole(); // ambil role user
      }
    });

    // jika sudah login, load role
    if (_session != null) {
      _loadUserRole();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUserRole() async {
    final uid = _session!.user.id;

    final response = await supabase
        .from('users')
        .select('role')
        .eq('id', uid)
        .maybeSingle();

    setState(() {
      _role = response?['role'];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // tidak ada session → ke login
    if (_session == null) return const LoginScreen();

    // ada session tapi role belum terbaca
    if (_role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // admin
    if (_role == 'admin') {
      return const AdminDashboard();
    }

    // user
    return const UserDashboard();
  }
}
