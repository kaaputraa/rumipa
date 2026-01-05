import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../models/room_model.dart';
// import '../../services/room_service.dart'; // Tidak lagi dibutuhkan di sini jika hanya menampilkan nama
import '../../widgets/custom_snackbar.dart';

class BookingScreen extends StatefulWidget {
  final UserModel user;
  final RoomModel selectedRoom; // [BARU] Menerima data room

  const BookingScreen({
    super.key,
    required this.user,
    required this.selectedRoom, // [BARU] Wajib diisi
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingService = BookingService();

  bool _isLoading = false;

  // Data
  List<BookingModel> _approvedBookings = [];
  bool _isFetchingAvailability = false;
  String? _availabilityFetchError;

  // Form Values
  late String
  _selectedRoomName; // [UBAH] Menjadi late karena diisi di initState
  final _purposeCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    // [BARU] Set ruangan langsung dari parameter widget
    _selectedRoomName = widget.selectedRoom.name;
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailabilityList() async {
    // _selectedRoomName pasti ada, jadi cek date saja
    if (_selectedDate == null) {
      setState(() => _approvedBookings = []);
      return;
    }

    setState(() {
      _isFetchingAvailability = true;
      _approvedBookings = [];
      _availabilityFetchError = null;
    });

    try {
      final list = await _bookingService.fetchUnavailableBookings(
        roomId: _selectedRoomName,
        date: _selectedDate!,
      );
      if (mounted) setState(() => _approvedBookings = list);
    } catch (e) {
      if (mounted)
        setState(() => _availabilityFetchError = 'Gagal memuat jadwal.');
    } finally {
      if (mounted) setState(() => _isFetchingAvailability = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchAvailabilityList();
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
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

  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _submit() async {
    final theme = Theme.of(context);

    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null) {
      showCustomSnackBar(
        context,
        message: 'Harap lengkapi semua data form!',
        isSuccess: false,
      );
      return;
    }

    if (_startTime!.hour > _endTime!.hour ||
        (_startTime!.hour == _endTime!.hour &&
            _startTime!.minute >= _endTime!.minute)) {
      showCustomSnackBar(
        context,
        message: 'Jam selesai harus setelah jam mulai.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startTimeStr = _timeOfDayToString(_startTime!);
      final endTimeStr = _timeOfDayToString(_endTime!);

      final isAvailable = await _bookingService.checkAvailability(
        roomId: _selectedRoomName,
        date: _selectedDate!,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );

      if (!isAvailable) {
        _fetchAvailabilityList();
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 36,
              ),
              title: const Text("Gagal Booking"),
              content: const Text(
                "Maaf, ruangan sudah terisi pada jam tersebut. Silakan cek jadwal di bawah.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Oke"),
                ),
              ],
            ),
          );
        }
        return;
      }

      final booking = BookingModel(
        userId: widget.user.id,
        roomId: _selectedRoomName,
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _buildGradientSuccessDialog(ctx, theme),
      );
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, message: 'Error: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          "Form Peminjaman",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      // [PERBAIKAN] Hapus FutureBuilder, langsung tampilkan Form
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INFORMASI PEMINJAM (Read Only Card)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_circle_rounded,
                      color: Colors.blue,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${widget.user.nim}  •  ${widget.user.phone}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                "Detail Peminjaman",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 2. RUANGAN (READ ONLY / LOCKED)
              // [PERBAIKAN] Mengganti Dropdown dengan TextFormField ReadOnly
              TextFormField(
                initialValue: widget.selectedRoom.name,
                readOnly: true, // Tidak bisa diedit
                decoration: const InputDecoration(
                  labelText: "Ruangan",
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(
                    0xFFEEEEEE,
                  ), // Warna abu-abu menandakan disabled
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // 3. KEPERLUAN
              TextFormField(
                controller: _purposeCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Keperluan Acara",
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),

              const SizedBox(height: 16),

              // 4. TANGGAL
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Tanggal Peminjaman",
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? "Pilih Tanggal"
                        : _selectedDate!.toIso8601String().substring(0, 10),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 5. JAM MULAI & SELESAI (Row)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(true),
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Jam Mulai",
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        child: Text(_startTime?.format(context) ?? "--:--"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(false),
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Jam Selesai",
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        child: Text(_endTime?.format(context) ?? "--:--"),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 6. AVAILABILITY STATUS (Dynamic UI)
              // Logic check: Room sudah pasti terpilih, tinggal cek tanggal
              if (_selectedDate != null) _buildAvailabilityStatus(),

              const SizedBox(height: 32),

              // 7. SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Ajukan Booking",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityStatus() {
    if (_isFetchingAvailability) {
      return Center(
        child: LinearProgressIndicator(
          color: Colors.grey.shade300,
          minHeight: 2,
        ),
      );
    }

    if (_availabilityFetchError != null) {
      return Text(
        _availabilityFetchError!,
        style: const TextStyle(color: Colors.red),
      );
    }

    if (_approvedBookings.isNotEmpty) {
      // JIKA ADA JADWAL TERISI
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Jadwal Terisi Hari Ini:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._approvedBookings.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "${b.startTime.substring(0, 5)} - ${b.endTime.substring(0, 5)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      " (${b.userName.isEmpty ? 'Booked' : b.userName})",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // JIKA KOSONG (AVAILABLE)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Ruangan tersedia sepanjang hari ini.",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGradientSuccessDialog(BuildContext context, ThemeData theme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, Colors.lightBlue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              "Pengajuan Berhasil!",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Permintaan Anda telah diajukan dan menunggu persetujuan Admin. Cek status di menu Riwayat.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Back to Dashboard
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Kembali ke Dashboard"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
