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

  // ============== FUNGSI ADMIN BARU ==============

  /// Mengambil semua daftar peminjaman dengan status tertentu
  Future<List<BookingModel>> fetchBookingsByStatus(String status) async {
    final response = await _client
        .from('bookings')
        .select()
        // Urutkan berdasarkan created_at terbaru
        .eq('status', status)
        .order('created_at', ascending: false);

    // Konversi hasil (List<Map>) menjadi List<BookingModel>
    return (response as List).map((map) => BookingModel.fromMap(map)).toList();
  }

  /// Memperbarui status peminjaman (Approve/Reject)
  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) async {
    // Admin dapat mengupdate status di SEMUA baris
    await _client
        .from('bookings')
        .update({'status': newStatus})
        .eq('id', bookingId);
  }

  // ============== FUNGSI USER BARU ==============

  /// Mengambil semua riwayat peminjaman untuk user tertentu
  Future<List<BookingModel>> fetchUserBookings(String userId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        // Urutkan berdasarkan created_at terbaru
        .order('created_at', ascending: false);

    return (response as List).map((map) => BookingModel.fromMap(map)).toList();
  }

  /// Mengambil daftar peminjaman dengan status Selesai dan Ditolak
  Future<List<BookingModel>> fetchHistoryBookings() async {
    final response = await _client
        .from('bookings')
        .select()
        // PERBAIKAN: Menggunakan .filter() dengan operator 'in' sebagai string
        .filter('status', 'in', ['completed', 'rejected'])
        .order('created_at', ascending: false);

    // Konversi hasil (List<Map>) menjadi List<BookingModel>
    return (response as List).map((map) => BookingModel.fromMap(map)).toList();
  }

  /// Memeriksa ketersediaan ruangan sebelum pemesanan
  /// Mengembalikan TRUE jika TIDAK ada konflik (tersedia), FALSE jika ada konflik (sudah dipesan)
  Future<bool> checkAvailability({
    required String roomId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    final dateString = date.toIso8601String().substring(0, 10);

    try {
      // 1. Cari booking yang sudah APPROVED
      // 2. Ruangan harus sama (roomId)
      // 3. Tanggal harus sama (dateString)
      // 4. Status harus 'approved'
      // 5. Waktu harus tumpang tindih (Logic: StartA < EndB AND EndA > StartB)

      final existingBookings = await _client
          .from('bookings')
          .select('start_time, end_time')
          .eq('room_id', roomId)
          .eq('date', dateString)
          .eq('status', 'approved')
          // Logika tumpang tindih (Overlap):
          .lt(
            'start_time',
            endTime,
          ) // Booking B mulai SEBELUM booking A selesai
          .gt(
            'end_time',
            startTime,
          ) // Booking B selesai SETELAH booking A mulai
          .limit(1); // Ambil 1 saja, karena 1 konflik sudah cukup

      // Jika hasilnya kosong (panjang 0), berarti TIDAK ada konflik.
      return (existingBookings as List).isEmpty;
    } catch (e) {
      // Jika terjadi error (misalnya RLS), asumsikan tidak tersedia untuk keamanan
      print('Error checking availability: $e');
      return false;
    }
  }
}
