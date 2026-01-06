// File: rumipa3/lib/src/services/storage_service.dart

import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'dart:typed_data'; // Jangan lupa import ini

class StorageService {
  final _client = Supabase.instance.client;

  // 1. KUNCI RAHASIA (32 Karakter untuk AES-256)
  final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');

  // 2. PERBAIKAN: IV HARUS TETAP (16 Karakter)
  // Jangan pakai .fromLength(16) karena itu random!
  final _iv = encrypt.IV.fromUtf8('16charslongiv123');

  /// Upload Encrypted KTM
  Future<String> uploadEncryptedKtm({
    required String uid,
    required File file,
  }) async {
    final fileBytes = await file.readAsBytes();

    // Enkripsi
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: _iv);

    // Path file
    final String path = '$uid/${const Uuid().v4()}.enc';

    try {
      await _client.storage
          .from('ktm')
          .uploadBinary(
            path,
            encrypted.bytes,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
              upsert: true,
            ),
          );
      return path;
    } catch (e) {
      rethrow;
    }
  }

  /// Download & Decrypt KTM
  Future<List<int>> downloadAndDecryptKtm(String path) async {
    try {
      // 1. Download file (apapun formatnya) dari Supabase
      final List<int> downloadedBytes = await _client.storage
          .from('ktm')
          .download(path);

      // 2. CEK EKSTENSI FILE
      // Jika file TIDAK diakhiri .enc, berarti itu file lama (JPG biasa).
      // Langsung kembalikan bytes aslinya tanpa didekripsi.
      if (!path.endsWith('.enc')) {
        return downloadedBytes;
      }

      // 3. Jika .enc, lakukan Dekripsi
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));

      final decryptedBytes = encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(downloadedBytes)),
        iv: _iv,
      );

      return decryptedBytes;
    } catch (e) {
      print("Error Processing KTM ($path): $e");
      // Opsi darurat: Jika dekripsi gagal, coba kembalikan apa adanya
      // (siapa tahu itu file gambar tapi salah nama ekstensi)
      // return []; // Atau return kosong biar UI menampilkan placeholder error
      rethrow;
    }
  }
}
