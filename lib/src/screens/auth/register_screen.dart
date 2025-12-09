import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [PENTING] Untuk memblokir input huruf
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Visibility State
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _loading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nimCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Create Auth User
      final authRes = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = authRes.user;
      if (user == null) {
        throw Exception("Gagal membuat akun");
      }

      final uid = user.id;

      // 2. Insert Profile to users Table
      await supabase
          .from('users')
          .insert({
            'id': uid,
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'nim': _nimCtrl.text.trim(),
            'role': 'user',
            'status': 'pending',
          })
          .select()
          .single();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrasi berhasil. Silakan login.'),
          backgroundColor: Colors.green.shade600,
        ),
      );

      Navigator.pop(context); // Kembali ke Login
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Warna
    const colorBg = Color(0xFFFAFAFB);
    const colorPrimaryBlue = Color(0xFF135BDA);
    const colorDarkBlue = Color(0xFF0F4BB5);
    const colorTextGray = Color(0xFF4E5153);
    const colorBorder = Color(0xFFCED4DA);

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. HEADER
                  Text(
                    'Create account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colorDarkBlue,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account so you can explore\nall the existing jobs',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. FORM FIELDS
                  // Nama
                  _buildTextField(
                    controller: _nameCtrl,
                    label: "Full Name",
                    borderColor: colorBorder,
                    textColor: colorTextGray,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 22),

                  // NIM (Aktifkan isNumber: true)
                  _buildTextField(
                    controller: _nimCtrl,
                    label: "NIM",
                    borderColor: colorBorder,
                    textColor: colorTextGray,
                    isNumber: true, // <--- Ini kuncinya
                    validator: (v) =>
                        v == null || v.isEmpty ? 'NIM wajib diisi' : null,
                  ),
                  const SizedBox(height: 22),

                  // Email
                  _buildTextField(
                    controller: _emailCtrl,
                    label: "Email",
                    borderColor: colorBorder,
                    textColor: colorTextGray,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Email tidak valid'
                        : null,
                  ),
                  const SizedBox(height: 22),

                  // Password
                  _buildTextField(
                    controller: _passwordCtrl,
                    label: "Password",
                    borderColor: colorBorder,
                    textColor: colorTextGray,
                    isPassword: true,
                    isObscure: !_isPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 22),

                  // Confirm Password
                  _buildTextField(
                    controller: _confirmPasswordCtrl,
                    label: "Confirm password",
                    borderColor: colorBorder,
                    textColor: colorTextGray,
                    isPassword: true,
                    isObscure: !_isConfirmPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Konfirmasi password wajib diisi';
                      if (v != _passwordCtrl.text) return 'Password tidak sama';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // 3. ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimaryBlue,
                        foregroundColor: const Color(0xFFECF3FA),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign up',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. FOOTER
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Have an account? Login',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: colorPrimaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGET ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color borderColor,
    required Color textColor,
    bool isPassword = false,
    bool isNumber = false, // Parameter untuk menandai input angka
    bool isObscure = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? isObscure : false,
        // Keyboard Type: Membantu menampilkan keyboard angka
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        // Input Formatters: Memaksa HANYA angka yang boleh masuk
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        style: GoogleFonts.inter(
          color: const Color(0xFF1A1C1E),
          fontWeight: FontWeight.w500,
        ),
        validator: validator,
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
            vertical: 18,
          ),

          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textColor,
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF135BDA), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
        ),
      ),
    );
  }
}
