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
    // Tampilkan dialog konfirmasi biar lebih UX friendly
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

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER SECTION (Custom AppBar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Text(
                              "Selamat Datang, ${user.name}",
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
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

                  // 2. STATUS CARD (Alert Box Modern)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // Jika lengkap: Biru Gradient, Jika belum: Oranye lembut
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

                  // 3. MENU GRID (Daftar Menu Modern)
                  // Menu 1: Peminjaman (Utama)
                  _buildMenuCard(
                    context: context,
                    title: "Pinjam Ruangan",
                    subtitle: "Cari dan booking ruangan",
                    icon: Icons.meeting_room_rounded,
                    color: theme.colorScheme.primary,
                    onTap: () => _checkAndNavigateToBooking(user),
                    isPrimary: true,
                  ),

                  const SizedBox(height: 16),

                  // Row untuk menu sekunder
                  Row(
                    children: [
                      // Menu 2: History
                      Expanded(
                        child: _buildMenuCard(
                          context: context,
                          title: "Riwayat",
                          subtitle: "Cek status",
                          icon: Icons.history_rounded,
                          color: Colors.purple,
                          onTap: _navigateToBookingHistory,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Menu 3: Edit Profile
                      Expanded(
                        child: _buildMenuCard(
                          context: context,
                          title: "Profil",
                          subtitle: "Edit data",
                          icon: Icons.person_outline_rounded,
                          color: Colors.teal,
                          onTap: _navigateToUpdateProfile,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper Widget untuk membuat Kartu Menu
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
          // Jika Primary pakai Row, jika tidak pakai Column biar muat
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isPrimary ? 32 : 24),
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
