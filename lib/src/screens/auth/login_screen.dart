import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Screens & Services
import '../home/user_dashboard.dart';
import '../home/admin_dashboard.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart'; // Import AuthService
import '../../widgets/custom_snackbar.dart'; // Import CustomSnackBar

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passwordC = TextEditingController();

  bool loading = false;
  bool _isPasswordVisible = false;

  final _authService = AuthService(); // Inisiasi AuthService

  // --- LOGIC AUTHENTICATION (Tetap Sama) ---
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

      final userData = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final role = userData['role'];

      if (!mounted) return;

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
      if (!mounted) return;
      // Menggunakan Custom SnackBar untuk pesan error
      showCustomSnackBar(context, message: 'Login gagal: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // =============================================
  // FUNGSI BARU: MENAMPILKAN DIALOG RESET PASSWORD
  // =============================================
  void _showResetPasswordDialog() {
    final resetEmailC = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Lupa Kata Sandi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Masukkan email Anda. Kami akan mengirimkan link untuk mereset kata sandi.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // Menggunakan TextField dengan styling yang konsisten
                  TextField(
                    controller: resetEmailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      // Menggunakan styling TextField yang sudah Anda definisikan di main.dart
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (resetEmailC.text.isEmpty ||
                              !resetEmailC.text.contains('@')) {
                            showCustomSnackBar(
                              context,
                              message: "Masukkan email yang valid.",
                              isSuccess: false,
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            await _authService.resetPassword(
                              email: resetEmailC.text.trim(),
                            );

                            if (!mounted) return;

                            Navigator.pop(ctx); // Tutup dialog

                            // Gunakan Custom SnackBar untuk pesan sukses
                            showCustomSnackBar(
                              context,
                              message:
                                  "Link reset telah dikirim ke email ${resetEmailC.text.trim()}. Periksa kotak masuk Anda.",
                              isSuccess: true,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            showCustomSnackBar(
                              context,
                              message: e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                              isSuccess: false,
                            );
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Kirim Link"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Warna dari Figma
    const colorPrimaryBlue = Color(0xFF135BDA);
    const colorDarkBlue = Color(0xFF0F4BB5);
    const colorTextGray = Color(0xFF4E5153);
    const colorBorder = Color(0xFFCED4DA);
    const colorBg = Color(0xFFFAFAFB);

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ), // Padding responsif
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. HEADER
                Text(
                  'Login here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorDarkBlue,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: 210,
                  child: Text(
                    'Welcome back you’ve been missed!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 48),
                // 2. FORM INPUTS
                // Email Field
                _buildTextField(
                  controller: emailC,
                  label: "Email",
                  borderColor: colorBorder,
                  textColor: colorTextGray,
                ),

                const SizedBox(height: 22),
                // Password Field
                _buildTextField(
                  controller: passwordC,
                  label: "Password",
                  borderColor: colorBorder,
                  textColor: colorTextGray,
                  isPassword: true,

                  suffixicon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF135BDA),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap:
                        _showResetPasswordDialog, // PANGGIL FUNGSI RESET DI SINI
                    child: Text(
                      'Forgot your password?',
                      style: GoogleFonts.inter(
                        color: colorPrimaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                // 3. LOGIN BUTTON
                SizedBox(
                  width: double.infinity, // Responsif: Full width parent
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimaryBlue,
                      foregroundColor: const Color(0xFFECF3FA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Sign in',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // 4. REGISTER LINK
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    'Create an account',
                    style: GoogleFonts.poppins(
                      // Figma pakai Poppins disini
                      color: colorPrimaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk Input Field agar kodenya rapi
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color borderColor,
    required Color textColor,
    bool isPassword = false,
    Widget? suffixicon,
  }) {
    return Container(
      // Container dekorasi sesuai Figma
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Kita gunakan InputBorder di TextField, tapi shadow bisa ditaruh sini jika perlu
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        style: GoogleFonts.inter(
          color: const Color(0xFF1A1C1E), // Warna input user (lebih gelap)
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.inter(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 18, // Padding Figma
          ),
          // icon mata
          suffixIcon: suffixicon,
          // Border saat normal
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          // Border saat diklik (Focus) - biasanya lebih gelap/biru
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF135BDA), width: 1.5),
          ),
        ),
      ),
    );
  }
}
