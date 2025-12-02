import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/screens/auth/register_screen.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rumipa3',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const RegisterScreen(), // ← TAMPILKAN REGISTER SCREEN
    );
  }
}
