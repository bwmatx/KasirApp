import 'package:flutter/material.dart';
import 'package:kasir_app/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await DBService.seedDummyData(); // Nonaktifkan untuk build final
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4FC3F7);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primary,
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // 🔥 START DARI LOGIN
    );
  }
}
