// rumipa3/lib/src/screens/auth/register_screen.dart

import 'package:flutter/material.dart'; // import 'dart:io'; dihapus
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:image_picker/image_picker.dart'; dihapus
// import '../../services/storage_service.dart'; dihapus

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  // final _phoneCtrl = TextEditingController(); Dihapus

  // File? _ktmFile; Dihapus
  bool _loading = false;

  final supabase = Supabase.instance.client;
  // final _storageService = StorageService(); Dihapus

  /// Pick KTM image from gallery Dihapus
  // Future<void> _pickKtm() async { ... }

  /// Handle register
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // if (_ktmFile == null) { ... } Dihapus

    setState(() => _loading = true);

    try {
      // -------------------
      // 1. Create Auth User
      // -------------------
      final authRes = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = authRes.user;
      if (user == null) {
        throw Exception("Gagal membuat akun");
      }

      final uid = user.id;

      // -------------------
      // 2. Upload KTM Image Dihapus
      // -------------------
      // final filePath = await _storageService.uploadKtm( ... ); Dihapus

      // -------------------
      // 3. Insert Profile to users Table
      // -------------------
      final insertRes = await supabase
          .from('users')
          .insert({
            'id': uid,
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'nim': _nimCtrl.text.trim(),
            'role': 'user',
            'status': 'pending', // user menunggu verifikasi
          })
          .select()
          .single();

      // HAPUS bagian ini:
      // if (insertRes.error != null) {
      //   throw Exception(insertRes.error!.message);
      // }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil. Silakan login.')),
      );

      Navigator.pop(context);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nimCtrl.dispose();
    // _phoneCtrl.dispose(); Dihapus
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Email tidak valid'
                      : null,
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _nimCtrl,
                  decoration: const InputDecoration(labelText: 'NIM'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'NIM wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // TextFormField untuk No. Telepon Dihapus
                // Widget untuk memilih KTM Dihapus
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
