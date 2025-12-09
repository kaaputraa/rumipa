import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rumipa3/src/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/screens/auth/register_screen.dart';
import 'src/core/session_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ddalbeqqtwyhdgbemzlg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkYWxiZXFxdHd5aGRnYmVtemxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2NzE0MDIsImV4cCI6MjA4MDI0NzQwMn0.ohv1WHroUb46Kv1TlzZVg5qlCvt7ODpu41sMPFnv-6U',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2962FF); // Electric Blue
    const backgroundColor = Color(0xFFF5F7FA); // Off-white
    const surfaceColor = Colors.white;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rumipa3',
      theme: ThemeData(
        useMaterial3: true,
        // Skema Warna
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: surfaceColor,
          background: backgroundColor,
          // Pastikan background benar-benar off-white, bukan default M3
          onBackground: const Color(0xFF1A1C1E),
        ),

        // Konfigurasi Font Global (Google Fonts)
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),

        // Styling Global untuk TextField (PENTING untuk look modern)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // Clean look tanpa border hitam
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),

        // Styling Global untuk Tombol
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0, // Flat design lebih modern
          ),
        ),
      ),
      home: const SessionHandler(),
    );
  }
}
