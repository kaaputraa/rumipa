import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Memuat data profil saat ini
  Future<void> _fetchProfile() async {
    try {
      final user = await _userService.fetchCurrentUserProfile();
      setState(() {
        _user = user;
        // PERBAIKAN: Gunakan operator null-coalescing dengan aman.
        _phoneCtrl.text = user.phone;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  /// Memilih gambar KTM dari galeri
  Future<void> _pickKtm() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _newKtmFile = File(picked.path));
  }

  /// Menyimpan perubahan profil (upload KTM dan update DB)
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    // Syarat: Jika KTM belum ada di DB dan pengguna belum memilih file baru
    if (_user!.ktmPath.isEmpty && _newKtmFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload Foto KTM dan isi No. Telepon'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    String finalKtmPath = _user!.ktmPath;
    final uid = Supabase.instance.client.auth.currentUser!.id;

    try {
      // 1. Upload file KTM baru jika ada
      if (_newKtmFile != null) {
        finalKtmPath = await _storageService.uploadKtm(
          uid: uid,
          file: _newKtmFile!,
        );
      }

      // 2. Update data di tabel users
      await _userService.updateProfile(
        uid: uid,
        phone: _phoneCtrl.text.trim(),
        ktmPath: finalKtmPath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );
      // Kembali ke dashboard setelah sukses
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perbarui Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Tentukan apakah KTM sudah ada atau belum
    final bool ktmExist = _user!.ktmPath.isNotEmpty && _newKtmFile == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Perbarui Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Status Verifikasi
                Card(
                  color: _user!.status == 'pending'
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Status Verifikasi: ${_user!.status.toUpperCase()}',
                      style: TextStyle(
                        color: _user!.status == 'pending'
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // No. Telepon
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'No. Telepon wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // KTM
                Text(
                  'Foto KTM (Kartu Tanda Mahasiswa)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),

                if (ktmExist)
                  // Tampilan jika KTM sudah ada di database
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Foto KTM saat ini sudah tersimpan.'),
                      FutureBuilder<String>(
                        future: _storageService.getSignedUrl(_user!.ktmPath),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Text('Gagal memuat pratinjau KTM.');
                          }
                          return Image.network(
                            snapshot.data!,
                            height: 200,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: _pickKtm,
                        icon: const Icon(Icons.edit),
                        label: const Text('Ganti Foto KTM'),
                      ),
                    ],
                  ),

                // Tampilan jika pengguna memilih file baru
                if (_newKtmFile != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.file(_newKtmFile!, height: 200),
                      TextButton.icon(
                        onPressed: () => setState(() => _newKtmFile = null),
                        icon: const Icon(Icons.delete),
                        label: const Text('Hapus & Pilih Ulang'),
                      ),
                    ],
                  )
                else if (!ktmExist)
                  // Tampilan jika belum ada KTM dan belum memilih file
                  ElevatedButton.icon(
                    onPressed: _pickKtm,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih Foto KTM'),
                  ),

                const SizedBox(height: 30),

                // Tombol Simpan
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
