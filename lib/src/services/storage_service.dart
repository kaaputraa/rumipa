import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _client = Supabase.instance.client;

  /// Upload a KTM file into bucket 'ktm' under path 'ktm/<uid>/<random>.jpg'
  /// Returns the path (not the public url).
  Future<String> uploadKtm({required String uid, required File file}) async {
    final String path = 'ktm/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final res = await _client.storage
          .from('ktm')
          .upload(
            path,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              metadata: {
                'owner': uid,
              }, // IMPORTANT: metadata owner for RLS storage policies
            ),
          );

      // If upload fails, Supabase throws or returns error; this returns path on success.
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
