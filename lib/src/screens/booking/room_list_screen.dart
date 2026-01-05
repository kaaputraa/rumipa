import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import 'booking_screen.dart';

class RoomListScreen extends StatefulWidget {
  final UserModel user;
  const RoomListScreen({super.key, required this.user});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _roomService = RoomService();
  Future<List<RoomModel>>? _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _roomService.fetchAllRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text(
          "Pilih Ruangan",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<RoomModel>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada ruangan tersedia",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rooms.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomCard(room);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // Navigasi ke BookingScreen dengan membawa data room
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BookingScreen(user: widget.user, selectedRoom: room),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card: HANYA NAMA RUANGAN (Indikator dihapus)
              Text(
                room.name,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 2. Deskripsi / Fasilitas
              Text(
                "Fasilitas & Deskripsi:",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                room.description.isNotEmpty
                    ? room.description
                    : "Tidak ada deskripsi",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // 3. Footer: Kapasitas & Tombol Pilih
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${room.capacity} Orang",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "Pilih Ruangan",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
