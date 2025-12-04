import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _client = Supabase.instance.client;

  /// Upload a KTM file into bucket 'ktm' under path '<uid>/<random>.jpg'
  /// Returns the path (relative to the bucket).
  Future<String> uploadKtm({required String uid, required File file}) async {
    // PERBAIKAN: Menghapus prefix 'ktm/' karena sudah ada .from('ktm') di bawah.
    // Path yang dibuat HARUS dimulai dengan UID.
    final String path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      await _client.storage
          .from('ktm') // Menargetkan bucket 'ktm'
          .upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              // Metadata 'owner' tidak diperlukan lagi karena RLS menggunakan auth.uid()
            ),
          );

      // Mengembalikan path relatif yang akan disimpan di tabel users (misal: 'uid-abc/timestamp.jpg')
      return path;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a signed URL valid for [expiresIn] seconds.
  Future<String> getSignedUrl(String path, {int expiresIn = 60}) async {
    final res = await _client.storage
        .from('ktm')
        .createSignedUrl(path, expiresIn);
    return res;
  }
}
