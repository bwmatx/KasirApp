import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../models/user.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const primary = Color(0xFF4FC3F7);
  static const dark = Color(0xFF0288D1);

  // Data yang bisa diedit
  String nama = '';
  String tglLahir = '';
  String namaToko = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    if (user != null) {
      nama = user.fullName;
      tglLahir = user.dob;
      namaToko = user.shopName;
      email = user.email;
    }
  }

  Future<void> _save() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final updatedUser = UserModel(
        username: user.username,
        fullName: nama,
        dob: tglLahir,
        shopName: namaToko,
        email: email,
        password: user.password,
      );
      await DBService.updateUser(updatedUser);
      AuthService.login(updatedUser); // Update session
    }
  }

  void logout(BuildContext context) {
    AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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

  Future<void> _editField({
    required String title,
    required String currentValue,
    required void Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SingleEditDialog(
        title: title,
        initialValue: currentValue,
        keyboardType: keyboardType,
      ),
    );

    if (result != null && mounted) {
      onSave(result);
      await _save();
      setState(() {});
    }
  }

  Future<void> _showEditAkunDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _MultiEditDialog(
        nama: nama,
        tglLahir: tglLahir,
        namaToko: namaToko,
        email: email,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        nama = result['nama']!;
        tglLahir = result['tglLahir']!;
        namaToko = result['namaToko']!;
        email = result['email']!;
      });
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTrx = TransactionService.history.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 20,
                20,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _headerStat('$totalTrx', 'Transaksi'),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      _headerStat(namaToko, 'Toko'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Informasi Akun (editable) ──
                  _sectionHeader(
                    'Informasi Akun',
                    onEdit: () async {
                      await _showEditAkunDialog();
                    },
                  ),
                  const SizedBox(height: 10),
                  _infoCard([
                    _editableRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Nama',
                      value: nama,
                      onTap: () => _editField(
                        title: 'Nama',
                        currentValue: nama,
                        onSave: (v) => setState(() => nama = v),
                      ),
                    ),
                    _divider(),
                    _editableRow(
                      icon: Icons.cake_rounded,
                      label: 'Tempat, Tgl Lahir',
                      value: tglLahir,
                      onTap: () => _editField(
                        title: 'Tempat, Tgl Lahir',
                        currentValue: tglLahir,
                        onSave: (v) => setState(() => tglLahir = v),
                      ),
                    ),
                    _divider(),
                    _editableRow(
                      icon: Icons.store_rounded,
                      label: 'Nama Toko',
                      value: namaToko,
                      onTap: () => _editField(
                        title: 'Nama Toko',
                        currentValue: namaToko,
                        onSave: (v) => setState(() => namaToko = v),
                      ),
                    ),
                    _divider(),
                    _editableRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                      keyboardType: TextInputType.emailAddress,
                      onTap: () => _editField(
                        title: 'Email',
                        currentValue: email,
                        keyboardType: TextInputType.emailAddress,
                        onSave: (v) => setState(() => email = v),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Aplikasi (tidak bisa diedit) ──
                  _sectionTitle('Aplikasi'),
                  const SizedBox(height: 10),
                  _infoCard([
                    _staticRow(Icons.info_outline_rounded, 'Versi', '1.0.0'),
                    _divider(),
                    _staticRow(
                      Icons.build_circle_outlined,
                      'Dibuat oleh',
                      'Adhi Wibowo',
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Hubungi Developer ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _hubungiDeveloper,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dark,
                        side: const BorderSide(color: primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.mail_outline_rounded, size: 20),
                      label: const Text(
                        'Hubungi Developer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Logout ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: Color(0xFFFFCDD2),
                            width: 1,
                          ),
                        ),
                      ),
                      onPressed: () => logout(context),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────

  Widget _sectionHeader(String title, {required VoidCallback onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF90A4AE),
            letterSpacing: 0.5,
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 13, color: dark),
                SizedBox(width: 4),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF90A4AE),
        letterSpacing: 0.5,
      ),
    );
  }

  static Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _editableRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: dark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF90A4AE),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFB0BEC5)),
          ],
        ),
      ),
    );
  }

  static Widget _staticRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: dark),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF90A4AE)),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _headerStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 62,
      color: Color(0xFFF0F4F8),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG WIDGETS (Dipisah ke class terpisah agar aman lifecycle controller-nya)
// ─────────────────────────────────────────────────────────────────────────────

class _SingleEditDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final TextInputType keyboardType;

  const _SingleEditDialog({
    required this.title,
    required this.initialValue,
    required this.keyboardType,
  });

  @override
  State<_SingleEditDialog> createState() => _SingleEditDialogState();
}

class _SingleEditDialogState extends State<_SingleEditDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Edit ${widget.title}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: TextField(
        controller: controller,
        keyboardType: widget.keyboardType,
        autofocus: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.title,
          filled: true,
          fillColor: const Color(0xFFF0F4F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: Color(0xFFCFD8DC)),
          ),
          child: const Text(
            'Batal',
            style: TextStyle(color: Color(0xFF90A4AE)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Simpan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MultiEditDialog extends StatefulWidget {
  final String nama;
  final String tglLahir;
  final String namaToko;
  final String email;

  const _MultiEditDialog({
    required this.nama,
    required this.tglLahir,
    required this.namaToko,
    required this.email,
  });

  @override
  State<_MultiEditDialog> createState() => _MultiEditDialogState();
}

class _MultiEditDialogState extends State<_MultiEditDialog> {
  late TextEditingController namaC;
  late TextEditingController tglC;
  late TextEditingController tokoC;
  late TextEditingController emailC;

  @override
  void initState() {
    super.initState();
    namaC = TextEditingController(text: widget.nama);
    tglC = TextEditingController(text: widget.tglLahir);
    tokoC = TextEditingController(text: widget.namaToko);
    emailC = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    namaC.dispose();
    tglC.dispose();
    tokoC.dispose();
    emailC.dispose();
    super.dispose();
  }

  Widget _dialogInput(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF0288D1)),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Edit Informasi Akun',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput(namaC, 'Nama', Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _dialogInput(tglC, 'Tempat, Tgl Lahir', Icons.cake_rounded),
            const SizedBox(height: 10),
            _dialogInput(tokoC, 'Nama Toko', Icons.store_rounded),
            const SizedBox(height: 10),
            _dialogInput(
              emailC,
              'Email',
              Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: Color(0xFFCFD8DC)),
          ),
          child: const Text(
            'Batal',
            style: TextStyle(color: Color(0xFF90A4AE)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'nama': namaC.text.trim().isEmpty
                  ? widget.nama
                  : namaC.text.trim(),
              'tglLahir': tglC.text.trim().isEmpty
                  ? widget.tglLahir
                  : tglC.text.trim(),
              'namaToko': tokoC.text.trim().isEmpty
                  ? widget.namaToko
                  : tokoC.text.trim(),
              'email': emailC.text.trim().isEmpty
                  ? widget.email
                  : emailC.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Simpan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
