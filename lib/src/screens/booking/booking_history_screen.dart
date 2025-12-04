import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _bookingService = BookingService();
  // Karena user_id dapat diakses melalui auth.currentUser, kita ambil langsung dari sana.
  final _userId = Supabase.instance.client.auth.currentUser!.id;
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = _bookingService.fetchUserBookings(_userId);
    });
  }

  // PERBAIKAN 1: Tambahkan case 'completed'
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue; // Ubah dari hijau ke biru untuk ongoing
      case 'completed': // <-- BARU
        return Colors.green; // Warna hijau untuk selesai
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  // PERBAIKAN 2: Tambahkan case 'completed'
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Disetujui (Berlangsung)';
      case 'completed': // <-- BARU
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu Persetujuan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Peminjaman'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings),
        ],
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error memuat riwayat: ${snapshot.error}'),
            );
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Anda belum memiliki riwayat peminjaman.'),
            );
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final statusColor = _getStatusColor(booking.status);

              // Format waktu peminjaman yang diajukan
              final String bookingTime =
                  '(${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)})';

              // Ambil waktu pengajuan LOKAL
              final DateTime? submittedTimeLocal = booking.createdAt?.toLocal();
              final String timeSubmitted = submittedTimeLocal != null
                  ? ' | Diajukan: ${submittedTimeLocal.hour.toString().padLeft(2, '0')}:${submittedTimeLocal.minute.toString().padLeft(2, '0')}'
                  : '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Text(
                      booking.status[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    // Gabungkan Tanggal Booking + Jam Booking + Jam Pengajuan (Lokal)
                    '${booking.roomId} - ${booking.date.toIso8601String().substring(0, 10)} $bookingTime$timeSubmitted',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Keperluan: ${booking.purpose}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatStatus(booking.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
