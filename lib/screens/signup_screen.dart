import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const primary = Color(0xFF4FC3F7);
  static const dark = Color(0xFF0288D1);

  final userController = TextEditingController();
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final shopController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  String error = '';

  @override
  void dispose() {
    userController.dispose();
    nameController.dispose();
    dobController.dispose();
    shopController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> register() async {
    final username = userController.text.trim();
    final name = nameController.text.trim();
    final dob = dobController.text.trim();
    final shop = shopController.text.trim();
    final email = emailController.text.trim();
    final pass = passController.text.trim();
    final confirm = confirmController.text.trim();

    if (username.isEmpty || name.isEmpty || dob.isEmpty || shop.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => error = 'Semua field harus diisi');
      return;
    }

    if (pass != confirm) {
      setState(() => error = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      error = '';
      _isLoading = true;
    });

    try {
      final user = UserModel(
        username: username,
        fullName: name,
        dob: dob,
        shopName: shop,
        email: email,
        password: pass,
      );

      await DBService.registerUser(user);

      if (!mounted) return;

      // Animasi Selamat Bergabung
      await _showSuccessAnimation();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      setState(() {
        error = 'Gagal mendaftar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showSuccessAnimation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Selamat Bergabung!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Akun Anda di KasirApp telah berhasil dibuat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: primary),
            ],
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              height: size.height * 0.25,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Daftar Akun',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mulai kelola tokomu dengan KasirApp',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                      child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _inputField(controller: userController, label: 'Username', icon: Icons.person_outline),
                  const SizedBox(height: 12),
                  _inputField(controller: nameController, label: 'Nama Lengkap', icon: Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: dobController,
                    label: 'Tanggal Lahir',
                    icon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 12),
                  _inputField(controller: shopController, label: 'Nama Toko', icon: Icons.storefront_outlined),
                  const SizedBox(height: 12),
                  _inputField(controller: emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: passController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _inputField(controller: confirmController, label: 'Konfirmasi Password', icon: Icons.lock_clock_outlined, obscure: _obscurePass),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Daftar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Login', style: TextStyle(fontSize: 13, color: dark, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: dark),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }
}
