import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    // Memuat data profil saat pertama kali dashboard dibuka
    _profileFuture = _userService.fetchCurrentUserProfile();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  void _navigateToUpdateProfile() async {
    // Navigasi ke halaman update profile
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateProfileScreen()),
    );

    // Muat ulang data profil setelah kembali (untuk update status kelengkapan)
    if (result == true || result == null) {
      setState(() {
        _profileFuture = _userService.fetchCurrentUserProfile();
      });
    }
  }

  void _navigateToBookingHistory() {
    // Navigasi ke Riwayat Peminjaman
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
    ).then((_) {
      // Muat ulang profil setelah kembali
      setState(() {
        _profileFuture = _userService.fetchCurrentUserProfile();
      });
    });
  }

  void _checkAndNavigateToBooking(UserModel user) {
    // Logika Pengecekan Kelengkapan Profil
    if (user.phone.isEmpty || user.ktmPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profil belum lengkap. Harap isi No. Telp dan upload KTM.',
          ),
        ),
      );
    } else {
      // NAVIGASI KE FORMULIR BOOKING
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingScreen(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToUpdateProfile,
            tooltip: 'Perbarui Profil',
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat data profil: ${snapshot.error}'),
            );
          }

          // Data profil sudah tersedia
          final user = snapshot.data!;
          final isProfileComplete =
              user.phone.isNotEmpty && user.ktmPath.isNotEmpty;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Selamat datang, ${user.name}!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),

                // Indikator Kelengkapan Profil
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    isProfileComplete
                        ? "Profil Anda LENGKAP"
                        : "PROFIL BELUM LENGKAP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isProfileComplete
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),

                // Tombol Akses Fitur Peminjaman
                ElevatedButton.icon(
                  onPressed: () => _checkAndNavigateToBooking(user),
                  icon: const Icon(Icons.meeting_room),
                  label: const Text('Akses Peminjaman Ruangan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProfileComplete
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(indent: 40, endIndent: 40),

                // Navigasi Riwayat Peminjaman
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: const Text('Riwayat Peminjaman'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToBookingHistory,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
