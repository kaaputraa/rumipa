import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _phoneCtrl = TextEditingController();

  File? _ktmFile;
  bool _loading = false;

  final supabase = Supabase.instance.client;

  /// Pick KTM image from gallery
  Future<void> _pickKtm() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _ktmFile = File(picked.path));
  }

  /// Handle register
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ktmFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan upload foto KTM')));
      return;
    }

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
      // 2. Upload KTM Image
      // -------------------
      final filePath = 'ktm/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('ktm')
          .upload(
            filePath,
            _ktmFile!,
            fileOptions: const FileOptions(upsert: true),
          );

      // -------------------
      // 3. Insert Profile to users Table
      // -------------------
      final insertRes = await supabase.from('users').insert({
        'id': uid,
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'nim': _nimCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'ktm_path': filePath,
        'role': 'user',
        'status': 'pending', // user menunggu verifikasi admin
      });

      if (insertRes.error != null) {
        throw Exception(insertRes.error!.message);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil. Menunggu verifikasi admin.'),
        ),
      );

      Navigator.pop(context);
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
    _phoneCtrl.dispose();
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
                const SizedBox(height: 8),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                _ktmFile == null
                    ? ElevatedButton.icon(
                        onPressed: _pickKtm,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pilih Foto KTM'),
                      )
                    : Column(
                        children: [
                          Image.file(_ktmFile!, height: 200),
                          TextButton.icon(
                            onPressed: () => setState(() => _ktmFile = null),
                            icon: const Icon(Icons.delete),
                            label: const Text('Hapus & Pilih Ulang'),
                          ),
                        ],
                      ),

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
