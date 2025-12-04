// rumipa3/lib/src/services/room_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';

class RoomService {
  final _client = Supabase.instance.client;

  /// Mengambil semua daftar ruangan yang tersedia
  Future<List<RoomModel>> fetchAllRooms() async {
    final response = await _client
        .from('rooms')
        .select()
        .order('name', ascending: true);

    if (response is List) {
      return response.map((map) => RoomModel.fromMap(map)).toList();
    }
    return [];
  }
}
