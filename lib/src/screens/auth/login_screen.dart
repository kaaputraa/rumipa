import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/user_dashboard.dart';
import '../home/admin_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passwordC = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    final supabase = Supabase.instance.client;

    try {
      setState(() => loading = true);

      final response = await supabase.auth.signInWithPassword(
        email: emailC.text.trim(),
        password: passwordC.text.trim(),
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw "Login gagal";
      }

      // ambil data user dari tabel users
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final role = userData['role'];

      // arahkan sesuai role
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // 1. HEADER / LOGO SECTION
                // Icon placeholder (bisa diganti Image.asset nanti)
                const Icon(
                  Icons.meeting_room_rounded,
                  size: 80,
                  color: Color(0xFF2962FF),
                ),
                const SizedBox(height: 24),
                Text(
                  "Selamat Datang",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Silahkan Login Untuk Menggunakan Aplikasi",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 48),

                // 2. FORM SECTION
                // Tidak perlu styling manual banyak-banyak karena sudah di Theme
                TextField(
                  controller: emailC,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),

                // const SizedBox(height: 12),
                // // Lupa Password (Opsional, tapi biasanya ada)
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: TextButton(
                //     onPressed: () {},
                //     child: Text(
                //       "Lupa Password?",
                //       style: TextStyle(color: Colors.grey.shade600),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 24),

                // 3. ACTION BUTTON (Gunakan FilledButton untuk Primary Action)
                SizedBox(
                  height: 56, // Tinggi tombol yang nyaman disentuh
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () => login(), // Panggil fungsi login
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. FOOTER (Register)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Tidak punya akun?",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                          color: Color(0xFF2962FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
