class BookingModel {
  final String? id;
  final String userId;
  final String roomId;
  final String userName;
  final String nim;
  final String phone;
  final String ktmPath; // <-- BARU: Tambahkan field ini
  final String purpose;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final DateTime? createdAt;

  BookingModel({
    this.id,
    required this.userId,
    required this.roomId,
    required this.userName,
    required this.nim,
    required this.phone,
    required this.ktmPath, // <-- BARU: Tambahkan ke constructor
    required this.purpose,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'pending',
    this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> m) {
    return BookingModel(
      id: m['id'],
      userId: m['user_id'],
      roomId: m['room_id'],
      userName: m['user_name'],
      nim: m['nim'],
      phone: m['phone'],
      ktmPath: m['ktm_path'] ?? '', // <-- BARU: Ambil dari DB
      purpose: m['purpose'],
      date: DateTime.parse(m['date']),
      startTime: m['start_time'],
      endTime: m['end_time'],
      status: m['status'] ?? 'pending',
      createdAt: m['created_at'] != null
          ? DateTime.parse(m['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'user_name': userName,
      'nim': nim,
      'phone': phone,
      'ktm_path': ktmPath, // <-- BARU: Masukkan ke Map untuk Supabase
      'purpose': purpose,
      'date': date.toIso8601String().substring(0, 10), // Format YYYY-MM-DD
      'start_time': startTime, // Format HH:MM:SS
      'end_time': endTime, // Format HH:MM:SS
      'status': status,
    };
  }
}
