import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';

class BookingScreen extends StatefulWidget {
  final UserModel user;
  const BookingScreen({super.key, required this.user});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingService = BookingService();
  final _roomService = RoomService();
  bool _isLoading = false;

  // Data Ruangan dan Ketersediaan
  Future<List<RoomModel>>? _roomsFuture;
  List<BookingModel> _approvedBookings = [];
  bool _isFetchingAvailability = false;
  String? _availabilityFetchError; // BARU: Status error fetching

  // Form Controllers/Values
  String? _selectedRoomName;
  final _purposeCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _roomService.fetchAllRooms();
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
  }

  /// Memuat daftar ruangan yang sudah terisi berdasarkan Room dan Date yang dipilih
  Future<void> _fetchAvailabilityList() async {
    // Hanya fetch jika kedua kriteria sudah dipilih
    if (_selectedRoomName == null || _selectedDate == null) {
      setState(() => _approvedBookings = []);
      return;
    }

    setState(() {
      _isFetchingAvailability = true;
      _approvedBookings = [];
      _availabilityFetchError = null; // Reset error
    });

    try {
      final list = await _bookingService.fetchUnavailableBookings(
        roomId: _selectedRoomName!,
        date: _selectedDate!,
      );

      if (mounted) {
        setState(() {
          _approvedBookings = list;
        });
      }
    } catch (e) {
      print('Error fetching approved bookings: $e');
      if (mounted) {
        setState(() {
          // Tampilkan pesan error jika fetch gagal (kemungkinan RLS)
          _availabilityFetchError =
              'Gagal memuat ketersediaan. Cek RLS SELECT di tabel bookings.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingAvailability = false);
      }
    }
  }

  /// Memilih tanggal
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      // Panggil fetch list setelah tanggal diubah
      _fetchAvailabilityList();
    }
  }

  /// Memilih waktu
  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  /// Mengubah TimeOfDay menjadi string format HH:MM:SS
  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  /// Mengajukan formulir peminjaman
  Future<void> _submit() async {
    // 1. Validasi form dasar
    if (!_formKey.currentState!.validate() ||
        _selectedRoomName == null ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data peminjaman!')),
      );
      return;
    }

    // 2. Validasi Waktu Selesai > Waktu Mulai
    if (_startTime!.hour > _endTime!.hour ||
        (_startTime!.hour == _endTime!.hour &&
            _startTime!.minute >= _endTime!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai harus setelah waktu mulai.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startTimeStr = _timeOfDayToString(_startTime!);
      final endTimeStr = _timeOfDayToString(_endTime!);

      // =======================================================
      // PENGECEKAN KONFLIK FINAL (Saat Submit)
      // =======================================================
      final isAvailable = await _bookingService.checkAvailability(
        roomId: _selectedRoomName!,
        date: _selectedDate!,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );

      if (!isAvailable) {
        // Jika konflik, panggil ulang list agar visualisasi terupdate jika data berubah saat ini.
        _fetchAvailabilityList();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Konflik! Ruangan sudah terpakai pada jam tersebut.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // =======================================================

      // 3. Jika tersedia, lanjutkan proses booking
      final booking = BookingModel(
        userId: widget.user.id,
        roomId: _selectedRoomName!,
        userName: widget.user.name,
        nim: widget.user.nim,
        phone: widget.user.phone,
        ktmPath: widget.user.ktmPath,
        purpose: _purposeCtrl.text.trim(),
        date: _selectedDate!,
        startTime: startTimeStr,
        endTime: endTimeStr,
        status: 'pending',
      );

      await _bookingService.submitBooking(booking);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Peminjaman berhasil diajukan. Menunggu persetujuan Admin.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan peminjaman: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulir Peminjaman Ruangan')),
      body: FutureBuilder<List<RoomModel>>(
        // Memuat data ruangan secara dinamis
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Gagal memuat ruangan: ${snapshot.error}'),
            );
          }

          final roomOptions = snapshot.data!;
          if (roomOptions.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada ruangan yang tersedia. Harap hubungi Admin.',
              ),
            );
          }

          // KOREKSI: Panggil fetch list saat ruangan pertama kali dimuat
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _selectedRoomName == null &&
                roomOptions.isNotEmpty) {
              setState(() {
                _selectedRoomName = roomOptions.first.name;
              });
              _fetchAvailabilityList();
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Data Pengguna (Read-only)
                  Text('Nama: ${widget.user.name}'),
                  Text('NIM: ${widget.user.nim}'),
                  Text('No. Telp: ${widget.user.phone}'),
                  const Divider(height: 20),

                  // Pilihan Ruangan (Menggunakan data dinamis)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Ruangan yang Dipinjam',
                    ),
                    value: _selectedRoomName,
                    items: roomOptions.map((room) {
                      return DropdownMenuItem(
                        value: room.name,
                        child: Text(room.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRoomName = value);
                      _fetchAvailabilityList(); // Panggil saat Ruangan diubah
                    },
                    validator: (v) =>
                        v == null ? 'Wajib memilih ruangan' : null,
                  ),
                  const SizedBox(height: 16),

                  // Keperluan Peminjaman
                  TextFormField(
                    controller: _purposeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keperluan Peminjaman',
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Keperluan wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Peminjaman
                  ListTile(
                    title: Text(
                      'Tanggal Peminjaman: ${_selectedDate?.toIso8601String().substring(0, 10) ?? "Pilih Tanggal"}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDate,
                  ),
                  const Divider(),

                  // Waktu Mulai
                  ListTile(
                    title: Text(
                      'Waktu Mulai: ${_startTime?.format(context) ?? "Pilih Waktu Mulai"}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(true),
                  ),
                  // Waktu Selesai
                  ListTile(
                    title: Text(
                      'Waktu Selesai: ${_endTime?.format(context) ?? "Pilih Waktu Selesai"}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(false),
                  ),
                  const Divider(height: 10),

                  // ===============================================
                  // TAMPILAN KETERSEDIAAN (Visual Feedback)
                  // ===============================================
                  Text(
                    'Jadwal Terisi pada ${_selectedDate?.toIso8601String().substring(0, 10) ?? "Tanggal Pilihan"}:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),

                  if (_isFetchingAvailability)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_availabilityFetchError !=
                      null) // Tampilkan error jika fetch gagal
                    Text(
                      _availabilityFetchError!,
                      style: TextStyle(color: Colors.red),
                    )
                  else if (_approvedBookings.isEmpty &&
                      _selectedRoomName != null &&
                      _selectedDate != null)
                    const Text(
                      'Ruangan kosong sepanjang hari yang dipilih. ✅',
                      style: TextStyle(color: Colors.green),
                    )
                  else if (_approvedBookings.isNotEmpty)
                    // Menampilkan list booking yang terisi
                    ..._approvedBookings.map((booking) {
                      final userName = booking.userName.isEmpty
                          ? 'Pengguna Lain'
                          : booking.userName;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          // Menampilkan waktu booking yang terisi
                          '${booking.startTime.substring(0, 5)} - ${booking.endTime.substring(0, 5)} (Dipinjam oleh: $userName)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 30),
                  // ===============================================

                  // Tombol Submit
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Ajukan Peminjaman'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
