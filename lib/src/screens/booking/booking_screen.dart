import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final UserModel user;
  const BookingScreen({super.key, required this.user});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingService = BookingService();
  bool _isLoading = false; // Menggunakan _isLoading untuk tombol submit

  // Controllers untuk formulir
  String? _selectedRoomId;
  final _purposeCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Contoh data ruangan (Gantilah ini dengan data dinamis jika Anda memiliki tabel rooms)
  final List<String> _roomOptions = ['R. 101', 'R. 102', 'Auditorium'];

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
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
    return '$hour:$minute:00'; // Format HH:MM:SS
  }

  /// Mengajukan formulir peminjaman
  Future<void> _submit() async {
    // 1. Validasi form dasar
    if (!_formKey.currentState!.validate() ||
        _selectedRoomId == null ||
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
      // KUNCI UTAMA: PENGECEKAN KONFLIK (Conflict Check)
      // =======================================================
      final isAvailable = await _bookingService.checkAvailability(
        roomId: _selectedRoomId!,
        date: _selectedDate!,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );

      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ruangan sudah terpakai pada jam tersebut. Silakan pilih jam atau ruangan lain.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Hentikan proses jika terjadi konflik
      }
      // =======================================================

      // 3. Jika tersedia, lanjutkan proses booking
      final booking = BookingModel(
        userId: widget.user.id,
        roomId: _selectedRoomId!,
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
      body: SingleChildScrollView(
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

              // Pilihan Ruangan
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Ruangan yang Dipinjam',
                ),
                value: _selectedRoomId,
                items: _roomOptions.map((room) {
                  return DropdownMenuItem(value: room, child: Text(room));
                }).toList(),
                onChanged: (value) => setState(() => _selectedRoomId = value),
                validator: (v) => v == null ? 'Wajib memilih ruangan' : null,
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
              const Divider(),

              const SizedBox(height: 24),

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
      ),
    );
  }
}
