import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_menu.dart';
import 'signup_screen.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const primary = Color(0xFF4FC3F7);
  static const dark = Color(0xFF0288D1);

  final userController = TextEditingController();
  final passController = TextEditingController();

  String error = '';
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      error = '';
      _isLoading = true;
    });

    final userText = userController.text.trim();
    final passText = passController.text.trim();

    if (userText.isEmpty || passText.isEmpty) {
      setState(() {
        error = 'Username dan password harus diisi';
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await DBService.loginUser(userText, passText);

      if (user != null) {
        AuthService.login(user);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeMenu()),
        );
      } else {
        setState(() {
          error = 'Username atau password salah';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _hubungiDeveloper() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'kwibowo437@yahoo.com',
      query: 'subject=KasirApp - Feedback',
    );
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Column(
            children: [
              // ── Top gradient header ──
              Container(
                width: double.infinity,
                height: size.height * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2.5),
                        ),
                        child: const Icon(Icons.store_rounded,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'KasirApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem Kasir Modern',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Form area ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Masuk ke Akun Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masukkan username dan password untuk melanjutkan',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF90A4AE)),
                      ),

                      const SizedBox(height: 24),

                      // Username
                      _inputField(
                        controller: userController,
                        label: 'Username',
                        icon: Icons.person_outline_rounded,
                        hint: 'Masukkan username',
                      ),

                      const SizedBox(height: 14),

                      // Password
                      TextField(
                        controller: passController,
                        obscureText: _obscurePass,
                        onSubmitted: (_) => login(),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Masukkan password',
                          hintStyle: const TextStyle(
                              color: Color(0xFFB0BEC5), fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 20, color: dark),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                              color: const Color(0xFFB0BEC5),
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                        ),
                      ),

                      // Error message
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text(
                                error,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primary.withValues(alpha: 0.6),
                            elevation: 4,
                            shadowColor: primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun? ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            ),
                            child: const Text('Daftar', style: TextStyle(fontSize: 13, color: dark, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Hubungi Developer
                      Center(
                        child: GestureDetector(
                          onTap: _hubungiDeveloper,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mail_outline_rounded,
                                  size: 15, color: Color(0xFF90A4AE)),
                              const SizedBox(width: 6),
                              const Text(
                                'Hubungi Developer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF90A4AE),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'v1.0.0 • Dibuat oleh Adhi Wibowo',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFB0BEC5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onSubmitted: (_) => login(),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: dark),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }
}
