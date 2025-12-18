import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/session_handler.dart';
import 'src/screens/auth/login_screen.dart'; // Pastikan import sesuai

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ddalbeqqtwyhdgbemzlg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkYWxiZXFxdHd5aGRnYmVtemxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2NzE0MDIsImV4cCI6MjA4MDI0NzQwMn0.ohv1WHroUb46Kv1TlzZVg5qlCvt7ODpu41sMPFnv-6U',
  );
  runApp(MyApp());
}

// GlobalKey untuk navigasi dari listener auth
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listener untuk mendeteksi link reset password dari email
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Asli Anda
    const primaryColor = Color(0xFF2962FF);
    const backgroundColor = Color(0xFFF5F7FA);
    const surfaceColor = Colors.white;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Rumipa3',
      theme: ThemeData(
        useMaterial3: true,
        // Mengembalikan Skema Warna Asli
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: surfaceColor,
          background: backgroundColor,
          onBackground: const Color(0xFF1A1C1E),
        ),

        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),

        // Mengembalikan Styling TextField Modern Anda
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),

        // Mengembalikan Styling Tombol Asli Anda
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
      home: const SessionHandler(),
    );
  }
}

// Halaman Update Password (Tetap dipertahankan)
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passC = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Masukkan Kata Sandi Baru Anda"),
            const SizedBox(height: 20),
            // Sekarang TextField ini akan mengikuti style Modern di atas secara otomatis
            TextField(
              controller: _passC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Baru",
                hintText: "Ketik password baru...",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Menggunakan FilledButton agar sesuai tema
                onPressed: _loading ? null : _handleUpdate,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan Password"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passC.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password berhasil diperbarui!")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
