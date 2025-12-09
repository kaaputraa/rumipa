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
  bool _isPasswordVisible = false;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Warna dari Figma [cite: 24, 42, 105]
    const colorPrimaryBlue = Color(0xFF135BDA);
    const colorDarkBlue = Color(0xFF0F4BB5);
    const colorTextGray = Color(0xFF4E5153);
    const colorBorder = Color(0xFFCED4DA);
    const colorBg = Color(0xFFFAFAFB); // [cite: 1]

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
                  'Login here', // [cite: 23]
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorDarkBlue, // [cite: 24]
                    fontSize: 34, // [cite: 25]
                    fontWeight: FontWeight.w800, // [cite: 26]
                  ),
                ),
                const SizedBox(height: 16), // Spacing dari Figma: 16 [cite: 22]

                SizedBox(
                  width: 210, // Membatasi lebar teks sesuai Figma [cite: 27]
                  child: Text(
                    'Welcome back you’ve been missed!', // [cite: 28]
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.black, // [cite: 29]
                      fontSize: 14, // [cite: 30]
                      fontWeight: FontWeight.w500,
                      height: 1.4, // Line height Figma [cite: 31]
                    ),
                  ),
                ),

                const SizedBox(height: 48), // Spacing antar section
                // 2. FORM INPUTS
                // Email Field
                _buildTextField(
                  controller: emailC,
                  label: "Email",
                  borderColor: colorBorder,
                  textColor: colorTextGray,
                ),

                const SizedBox(height: 22), // Spacing 22 [cite: 36]
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
                    onTap: () {
                      // TODO: Implement forgot password
                    },
                    child: Text(
                      'Forgot your password?', // Fixed typo "yor" -> "your" [cite: 104]
                      style: GoogleFonts.inter(
                        color: colorPrimaryBlue, // [cite: 105]
                        fontSize: 12, // [cite: 106]
                        fontWeight:
                            FontWeight.w600, // Sedikit lebih tebal agar terbaca
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32), // Spacing 32 [cite: 21]
                // 3. LOGIN BUTTON
                SizedBox(
                  width: double.infinity, // Responsif: Full width parent
                  height: 48, // Tinggi dari Figma [cite: 109]
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimaryBlue, // [cite: 110]
                      foregroundColor: const Color(
                        0xFFECF3FA,
                      ), // Warna Teks [cite: 115]
                      elevation: 0, // Desain Figma flat
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // [cite: 111]
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
                            'Sign in', // [cite: 113]
                            style: GoogleFonts.inter(
                              fontSize: 16, // [cite: 115]
                              fontWeight: FontWeight.w700, // [cite: 116]
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
                    'Create an account', // [cite: 121]
                    style: GoogleFonts.poppins(
                      // Figma pakai Poppins disini
                      color: colorPrimaryBlue, // [cite: 122]
                      fontSize: 14,
                      fontWeight: FontWeight.w600, // [cite: 124]
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
      // Container dekorasi sesuai Figma [cite: 37-44]
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
          hintText: label, // [cite: 54, 82]
          hintStyle: GoogleFonts.inter(
            color: textColor, // [cite: 56]
            fontSize: 14,
            fontWeight: FontWeight.w500, // [cite: 58]
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 18, // Padding Figma [cite: 39]
          ),
          // icon mata
          suffixIcon: suffixicon,
          // Border saat normal
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // [cite: 43]
            borderSide: BorderSide(
              color: borderColor,
              width: 1,
            ), // [cite: 41-42]
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
