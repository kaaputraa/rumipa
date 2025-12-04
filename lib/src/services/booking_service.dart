import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingService {
  final _client = Supabase.instance.client;

  /// Mengajukan peminjaman ruangan baru
  Future<void> submitBooking(BookingModel booking) async {
    try {
      await _client.from('bookings').insert(booking.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Mengambil semua daftar peminjaman dengan status tertentu
  Future<List<BookingModel>> fetchBookingsByStatus(String status) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);

    return (response as List).map((map) => BookingModel.fromMap(map)).toList();
  }

  /// Memperbarui status peminjaman (Approve/Reject/Complete)
  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) async {
    await _client
        .from('bookings')
        .update({'status': newStatus})
        .eq('id', bookingId);
  }

  // ===============================================
  // FUNGSI UNTUK RIWAYAT DAN KETERSEDIAAN
  // ===============================================

  /// Mengambil daftar peminjaman dengan status Selesai dan Ditolak (History Admin)
  Future<List<BookingModel>> fetchHistoryBookings() async {
    final response = await _client
        .from('bookings')
        .select()
        .filter('status', 'in', ['completed', 'rejected'])
        .order('created_at', ascending: false);

    return (response as List).map((map) => BookingModel.fromMap(map)).toList();
  }

  /// Mengambil semua riwayat peminjaman untuk user tertentu (History User)
  Future<List<BookingModel>> fetchUserBookings(String userId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((map) => BookingModel.fromMap(map)).toList();
  }

  /// Mengambil daftar booking yang sudah disetujui ATAU masih pending (Visualisasi Ketersediaan)
  Future<List<BookingModel>> fetchUnavailableBookings({
    required String roomId,
    required DateTime date,
  }) async {
    final dateString = date.toIso8601String().substring(0, 10);

    final response = await _client
        .from('bookings')
        // KOREKSI: Mengambil SEMUA field (tanda '*') untuk memastikan BookingModel.fromMap
        // mendapatkan semua data yang diperlukan, termasuk user_name, phone, dll.
        .select('*')
        .eq('room_id', roomId)
        .eq('date', dateString)
        .filter('status', 'in', ['approved', 'pending'])
        .order('start_time', ascending: true);

    return (response as List).map((map) => BookingModel.fromMap(map)).toList();
  }

  /// Memeriksa ketersediaan ruangan (Conflict Check) - Logic ini sudah benar.
  Future<bool> checkAvailability({
    required String roomId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    final dateString = date.toIso8601String().substring(0, 10);

    try {
      final existingBookings = await _client
          .from('bookings')
          .select('start_time') // Cukup minimalis
          .eq('room_id', roomId)
          .eq('date', dateString)
          .neq('status', 'rejected')
          .lt('start_time', endTime)
          .gt('end_time', startTime)
          .limit(1);

      return (existingBookings as List).isEmpty;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }
}
