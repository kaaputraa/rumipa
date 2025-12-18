import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../profile/update_profile_screen.dart';
import '../booking/booking_history_screen.dart';
import '../booking/booking_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _userService = UserService();
  Future<UserModel>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _userService.fetchCurrentUserProfile();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          // Menggunakan TextButton yang default-nya primary color
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      }
    }
  }

  void _navigateToUpdateProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateProfileScreen()),
    );
    if (result == true || result == null) {
      setState(() {
        _profileFuture = _userService.fetchCurrentUserProfile();
      });
    }
  }

  void _navigateToBookingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
    ).then((_) {
      setState(() {
        _profileFuture = _userService.fetchCurrentUserProfile();
      });
    });
  }

  void _checkAndNavigateToBooking(UserModel user) {
    if (user.phone.isEmpty || user.ktmPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profil belum lengkap. Lengkapi data untuk meminjam.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Lengkapi',
            textColor: Colors.white,
            onPressed: _navigateToUpdateProfile,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingScreen(user: user)),
      );
    }
  }

  // Helper untuk mengambil nama belakang saja
  String _getLastName(String fullName) {
    if (fullName.isEmpty) return "User";
    List<String> parts = fullName.trim().split(' ');
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: FutureBuilder<UserModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data!;
          final isProfileComplete =
              user.phone.isNotEmpty && user.ktmPath.isNotEmpty;

          // Ambil nama belakang
          final lastName = _getLastName(user.name);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menggunakan Expanded agar teks tidak menabrak tombol logout
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selamat Datang, $lastName", // Nama Belakang
                              maxLines: 1, // Batasi 1 baris
                              overflow: TextOverflow
                                  .ellipsis, // Titik-titik jika kepanjangan
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight
                                    .bold, // Sedikit ditebalkan agar bagus
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ), // Jarak aman antara teks dan tombol
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                          onPressed: _logout,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 2. STATUS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: isProfileComplete
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                const Color(0xFF64B5F6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.orange.shade700,
                                Colors.orange.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isProfileComplete
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isProfileComplete
                                  ? Icons.verified_user_rounded
                                  : Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isProfileComplete
                                  ? "Akun Terverifikasi"
                                  : "Profil Belum Lengkap",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isProfileComplete
                              ? "Anda sudah dapat melakukan peminjaman ruangan."
                              : "Lengkapi data diri (No. HP & KTM) untuk mulai meminjam.",
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        if (!isProfileComplete) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _navigateToUpdateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Lengkapi Sekarang"),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    "Menu Utama",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. MENU LIST (Vertical Stack)
                  // Semua button sekarang Full Width & seragam

                  // Menu 1: Peminjaman
                  _buildMenuCard(
                    context: context,
                    title: "Pinjam Ruangan",
                    subtitle: "Cari dan booking ruangan",
                    icon: Icons.meeting_room_rounded,
                    color: theme.colorScheme.primary,
                    onTap: () => _checkAndNavigateToBooking(user),
                    isPrimary: true, // Ada arrow icon
                  ),

                  const SizedBox(height: 16),

                  // Menu 2: Riwayat (Full Width)
                  _buildMenuCard(
                    context: context,
                    title: "Riwayat Peminjaman",
                    subtitle: "Cek status pengajuan",
                    icon: Icons.history_rounded,
                    color: Colors.purple,
                    onTap: _navigateToBookingHistory,
                    isPrimary: true, // Ada arrow icon agar seragam
                  ),

                  const SizedBox(height: 16),

                  // Menu 3: Profil (Full Width)
                  _buildMenuCard(
                    context: context,
                    title: "Profil Saya",
                    subtitle: "Edit data & informasi akun",
                    icon: Icons.person_outline_rounded,
                    color: Colors.teal,
                    onTap: _navigateToUpdateProfile,
                    isPrimary: true, // Ada arrow icon agar seragam
                  ),

                  const SizedBox(height: 32), // Extra padding bottom
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper Widget
  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32), // Ukuran icon seragam
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            // Selalu tampilkan panah jika isPrimary true (sekarang semua true)
            if (isPrimary)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade300,
              ),
          ],
        ),
      ),
    );
  }
}
