import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/booking_service.dart';
import '../../services/storage_service.dart';
import '../../models/booking_model.dart';

// =========================================================
// ADMIN DASHBOARD UTAMA (3 TAB)
// =========================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // TIGA tab: Pending, Approved/Pengembalian, dan Riwayat
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Keluar',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Menunggu', icon: Icon(Icons.pending_actions)),
              Tab(text: 'Pengembalian', icon: Icon(Icons.check_circle_outline)),
              Tab(text: 'Riwayat', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1: Permintaan yang Perlu Persetujuan (Pending)
            BookingListWidget(statusFilter: 'pending'),

            // Tab 2: Peminjaman yang Sudah Disetujui (Ready for Return)
            BookingListWidget(statusFilter: 'approved'),

            // Tab 3: Riwayat (Selesai dan Ditolak)
            HistoryListWidget(),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// WIDGET UTAMA UNTUK MENAMPILKAN DAFTAR BOOKING
// =========================================================

class BookingListWidget extends StatefulWidget {
  final String statusFilter;
  const BookingListWidget({super.key, required this.statusFilter});

  @override
  State<BookingListWidget> createState() => _BookingListWidgetState();
}

class _BookingListWidgetState extends State<BookingListWidget> {
  final _bookingService = BookingService();
  final _storageService = StorageService();
  Future<List<BookingModel>>? _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void didUpdateWidget(covariant BookingListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusFilter != widget.statusFilter) {
      _loadBookings();
    }
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = _bookingService.fetchBookingsByStatus(
        widget.statusFilter,
      );
    });
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        newStatus: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status peminjaman berhasil diperbarui menjadi ${newStatus.toUpperCase()}',
            ),
          ),
        );
      }
      _loadBookings(); // Muat ulang daftar setelah update
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
      }
    }
  }

  Widget _buildKtmPreview(String ktmPath) {
    if (ktmPath.isEmpty) {
      return const Text(
        'KTM Path Kosong.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return FutureBuilder<String>(
      future: _storageService.getSignedUrl(ktmPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text(
            'Gagal memuat pratinjau KTM. Cek RLS SELECT Storage Admin.',
          );
        }
        return Image.network(
          snapshot.data!,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Gambar KTM tidak dapat dimuat.');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookingModel>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error memuat peminjaman: ${snapshot.error}'),
          );
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          String message = widget.statusFilter == 'pending'
              ? 'Tidak ada permintaan peminjaman yang tertunda.'
              : 'Tidak ada peminjaman yang sedang berlangsung.';
          return Center(child: Text(message));
        }

        final bookings = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];

            // Format waktu peminjaman yang diajukan
            final String bookingTime =
                '${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)}';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                // KOREKSI: Tambahkan Jam Booking ke Title
                title: Text(
                  '${booking.roomId} - ${booking.userName} (${booking.date.toIso8601String().substring(0, 10)})',
                ),
                subtitle: Text(
                  'Keperluan: ${booking.purpose} | Waktu: $bookingTime',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hapus baris Tanggal/Waktu lama jika sudah ada di subtitle ExpansionTile
                        // Text('Tanggal: ${booking.date.toIso8601String().substring(0, 10)}'),
                        // Text('Waktu: ${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)}'),
                        Text(
                          'Tanggal Peminjaman: ${booking.date.toIso8601String().substring(0, 10)}',
                        ),
                        Text('Durasi Peminjaman: $bookingTime'),
                        Text(
                          'Diajukan pada: ${booking.createdAt != null ? '${booking.createdAt!.day}/${booking.createdAt!.month} ${booking.createdAt!.hour.toString().padLeft(2, '0')}:${booking.createdAt!.minute.toString().padLeft(2, '0')}' : '-'}',
                        ),
                        const Divider(height: 15),
                        Text('NIM: ${booking.nim}'),
                        Text('Telepon: ${booking.phone}'),
                        const SizedBox(height: 10),

                        // Bagian KTM
                        const Text(
                          'Foto KTM (Verifikasi)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        _buildKtmPreview(booking.ktmPath),
                        const SizedBox(height: 10),

                        // Tombol Aksi
                        _buildActionButtons(booking),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    // Aksi untuk tab 'pending'
    if (widget.statusFilter == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _updateStatus(booking.id!, 'rejected'),
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _updateStatus(booking.id!, 'approved'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }
    // Aksi untuk tab 'approved' (Fitur Pengembalian)
    else if (widget.statusFilter == 'approved') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _updateStatus(
              booking.id!,
              'completed',
            ), // Status baru: completed
            icon: const Icon(Icons.key_off, color: Colors.white),
            label: const Text(
              'Kunci Dikembalikan / Selesai',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// =========================================================
// WIDGET KHUSUS RIWAYAT
// =========================================================

class HistoryListWidget extends StatefulWidget {
  const HistoryListWidget({super.key});

  @override
  State<HistoryListWidget> createState() => _HistoryListWidgetState();
}

class _HistoryListWidgetState extends State<HistoryListWidget> {
  final _bookingService = BookingService();
  Future<List<BookingModel>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _bookingService.fetchHistoryBookings();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'rejected':
        return 'DITOLAK';
      case 'completed':
        return 'SELESAI';
      default:
        return 'ARSIP';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookingModel>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error memuat riwayat: ${snapshot.error}'));
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Tidak ada riwayat peminjaman (Ditolak/Selesai).'),
          );
        }

        final bookings = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final statusColor = _getStatusColor(booking.status);
            final statusText = _formatStatus(booking.status);

            // Format waktu peminjaman yang diajukan
            final String bookingTime =
                '(${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)})';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  booking.status == 'rejected'
                      ? Icons.cancel
                      : Icons.check_circle,
                  color: statusColor,
                ),
                // KOREKSI: Tambahkan Jam Booking ke Title
                title: Text(
                  '${booking.roomId} - ${booking.date.toIso8601String().substring(0, 10)} $bookingTime',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Keperluan: ${booking.purpose}'),
                trailing: Chip(
                  label: Text(statusText),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
