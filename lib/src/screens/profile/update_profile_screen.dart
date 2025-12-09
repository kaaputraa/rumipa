import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [PENTING] Tambahan import untuk filter input
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/storage_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  final _userService = UserService();
  final _storageService = StorageService();

  UserModel? _user;
  File? _newKtmFile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await _userService.fetchCurrentUserProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _phoneCtrl.text = user.phone;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
      }
    }
  }

  Future<void> _pickKtm() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _newKtmFile = File(picked.path));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    if (_user!.ktmPath.isEmpty && _newKtmFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan upload Foto KTM')));
      return;
    }

    setState(() => _isSaving = true);
    String finalKtmPath = _user!.ktmPath;
    final uid = Supabase.instance.client.auth.currentUser!.id;

    try {
      if (_newKtmFile != null) {
        finalKtmPath = await _storageService.uploadKtm(
          uid: uid,
          file: _newKtmFile!,
        );
      }

      await _userService.updateProfile(
        uid: uid,
        phone: _phoneCtrl.text.trim(),
        ktmPath: finalKtmPath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFFAFAFB);
    const colorPrimaryBlue = Color(0xFF135BDA);
    const colorHeader = Color(0xFF03122B);
    const colorTextGray = Color(0xFF4E5153);
    const colorBorder = Color(0xFFCED4DA);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: colorBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: colorBg,
        body: Center(child: Text("Gagal memuat data user")),
      );
    }

    final bool ktmExist = _user!.ktmPath.isNotEmpty;

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: colorHeader,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: GoogleFonts.inter(
                        color: colorHeader,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

                // [DIHAPUS] Bagian Status Badge sudah dihilangkan dari sini
                const SizedBox(height: 32),

                // 2. FORM FIELDS
                _buildReadOnlyField(
                  label: "Nama Lengkap",
                  value: _user!.name,
                  colorBorder: colorBorder,
                  colorText: colorTextGray,
                ),
                const SizedBox(height: 22),

                _buildReadOnlyField(
                  label: "NIM",
                  value: _user!.nim,
                  colorBorder: colorBorder,
                  colorText: colorTextGray,
                ),
                const SizedBox(height: 22),

                _buildReadOnlyField(
                  label: "Email",
                  value: _user!.email,
                  colorBorder: colorBorder,
                  colorText: colorTextGray,
                ),
                const SizedBox(height: 22),

                // Field: No HP (Perbaikan Validasi di sini)
                _buildEditableField(
                  controller: _phoneCtrl,
                  hint: "Nomor Telphone",
                  colorBorder: colorBorder,
                  colorText: colorTextGray,
                  isNumber: true, // Flag ini mengaktifkan filter angka
                ),
                const SizedBox(height: 22),

                // Field: Bukti Identitas
                _buildKtmPicker(
                  ktmExist: ktmExist,
                  colorBorder: colorBorder,
                  colorText: colorTextGray,
                  colorPrimary: colorPrimaryBlue,
                ),

                const SizedBox(height: 44),

                // 3. TOMBOL SIMPAN
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimaryBlue,
                      foregroundColor: const Color(0xFFECF3FA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Simpan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required Color colorBorder,
    required Color colorText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorder, width: 1),
      ),
      child: Text(
        value.isEmpty ? label : value,
        style: GoogleFonts.inter(
          color: colorText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String hint,
    required Color colorBorder,
    required Color colorText,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        // Keyboard type numeric agar UX keyboard angka muncul
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        // [PERBAIKAN UTAMA] Memaksa input hanya boleh angka
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        style: GoogleFonts.inter(
          color: colorText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF135BDA), width: 1.5),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Data ini wajib diisi';
          // Validasi tambahan: Minimal 10 digit jika ini nomor telepon
          if (isNumber && v.length < 10)
            return 'Nomor HP tidak valid (min 10 digit)';
          return null;
        },
      ),
    );
  }

  Widget _buildKtmPicker({
    required bool ktmExist,
    required Color colorBorder,
    required Color colorText,
    required Color colorPrimary,
  }) {
    return GestureDetector(
      onTap: _pickKtm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bukti Identitas (KTM)',
                  style: GoogleFonts.inter(
                    color: colorText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.upload_file, color: colorPrimary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            if (_newKtmFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _newKtmFile!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap untuk ganti foto",
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
              ),
            ] else if (ktmExist) ...[
              FutureBuilder<String>(
                future: _storageService.getSignedUrl(_user!.ktmPath),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        snapshot.data!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Text("Gagal memuat gambar"),
                      ),
                    );
                  }
                  return const LinearProgressIndicator();
                },
              ),
            ] else ...[
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Belum ada foto.\nTap untuk upload.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
