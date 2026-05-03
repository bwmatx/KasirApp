import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/cart_service.dart';
import '../services/transaction_service.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'product_list_screen.dart';
import 'profile_screen.dart';
import '../models/product.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4FC3F7);

    final pages = [
      const _Dashboard(),
      const ProductListScreen(),
      CartScreen(cartItems: CartService.cart),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ).then((val) {
            setState(() {
              if (val == 'cart') index = 2;
            });
          });
        },
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        surfaceTintColor: Colors.white,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nav(Icons.home_rounded, 'Home', 0),
              _nav(Icons.inventory_2_rounded, 'Produk', 1),
              const SizedBox(width: 56),
              _nav(Icons.shopping_cart_rounded, 'Cart', 2),
              _nav(Icons.person_rounded, 'Akun', 3),
            ],
          ),
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int i) {
    final active = index == i;
    const activeColor = Color(0xFF0288D1);
    const inactiveColor = Color(0xFFB0BEC5);

    return InkWell(
      onTap: () => setState(() => index = i),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? activeColor : inactiveColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DASHBOARD =================

class _Dashboard extends StatefulWidget {
  const _Dashboard();

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  final phoneController = TextEditingController();

  String _rp(num n) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(n);

  Future<void> _pickContact(StateSetter setModalState) async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return;
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null && contact.phones.isNotEmpty) {
      setModalState(() {
        phoneController.text = contact.phones.first.number;
      });
      setState(() {});
    }
  }

  void _showTrxDetail(BuildContext context, TransactionModel trx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      _infoRow('Waktu', trx.time),
                      _infoRow('Metode', trx.method),
                      const SizedBox(height: 16),
                      const Text(
                        'Item Terjual:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...trx.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} x ${_rp(item.product.price)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _rp(item.product.price * item.quantity),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                      _totalRow('Total', trx.total, isBold: true),
                      if (trx.method == 'CASH') ...[
                        _totalRow('Bayar', trx.uangBayar),
                        _totalRow(
                          'Kembali',
                          trx.kembalian,
                          color: Colors.green,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Kirim ke Pelanggan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Nomor WhatsApp',
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                prefixIcon: const Icon(
                                  Icons.chat_rounded,
                                  color: Color(0xFF25D366),
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F7F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _pickContact(setModalState),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.contacts_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareWA(context, trx),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Kirim WA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printPDF(trx),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('Cetak PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    double val, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _rp(val),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWA(BuildContext context, TransactionModel trx) async {
    final phone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/struk_history.png');

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) => pw.Container(
            color: PdfColors.white,
            child: _buildReceiptContent(trx),
          ),
        ),
      );

      final bytes = await doc.save();
      await for (var page in Printing.raster(bytes, pages: [0], dpi: 200)) {
        final image = await page.toPng();
        await file.writeAsBytes(image);
        break;
      }

      const platform = MethodChannel('com.example.kasir_app/share');
      await platform.invokeMethod('shareToWhatsApp', {
        'phone': phone,
        'filePath': file.path,
        'text': 'Berikut adalah struk belanja Anda.',
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim WA: $e')));
    }
  }

  pw.Widget _dashedDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Divider(
        borderStyle: pw.BorderStyle.dashed,
        color: PdfColors.black,
        thickness: 1,
      ),
    );
  }

  pw.Widget _buildReceiptContent(TransactionModel trx) {
    final styleBase = const pw.TextStyle(fontSize: 10);
    final styleBold = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Text('PESANAN', style: styleBase)),
          if (phoneController.text.isNotEmpty)
            pw.Center(
              child: pw.Text(
                'No Telp ${phoneController.text}',
                style: styleBase,
              ),
            ),
          _dashedDivider(),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 60,
                child: pw.Text('Pelanggan', style: styleBase),
              ),
              pw.Text(' : Umum', style: styleBase),
            ],
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 60, child: pw.Text('Waktu', style: styleBase)),
              pw.Text(' : ${trx.time}', style: styleBase),
            ],
          ),
          pw.Text('Struk Pesanan', style: styleBase),
          pw.Text('Take Away', style: styleBase),
          _dashedDivider(),
          ...trx.items.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final e = entry.value;
            final sub = e.product.price * e.quantity;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$idx. ${e.product.name}', style: styleBase),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12),
                      child: pw.Text(
                        '${e.quantity} x ${_rp(e.product.price)}',
                        style: styleBase,
                      ),
                    ),
                    pw.Text(_rp(sub), style: styleBase),
                  ],
                ),
              ],
            );
          }),
          _dashedDivider(),
          pw.Text(
            'Total QTY : ${trx.items.fold<int>(0, (p, c) => p + c.quantity)}',
            style: styleBase,
          ),
          _dashedDivider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Sub Total', style: styleBase),
              pw.Text(_rp(trx.total), style: styleBase),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total', style: styleBold),
              pw.Text(_rp(trx.total), style: styleBold),
            ],
          ),
          if (trx.method == 'CASH') ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bayar', style: styleBase),
                pw.Text(_rp(trx.uangBayar), style: styleBase),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Kembali', style: styleBase),
                pw.Text(
                  _rp(trx.kembalian > 0 ? trx.kembalian : 0),
                  style: styleBase,
                ),
              ],
            ),
          ],
          _dashedDivider(),
          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('Bukan Bukti Pembayaran', style: styleBase)),
          pw.Center(
            child: pw.Text('Terimakasih Telah Berbelanja di', style: styleBase),
          ),
          pw.Center(child: pw.Text('Toko Kami', style: styleBase)),
        ],
      ),
    );
  }

  Future<void> _printPDF(TransactionModel trx) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) => pw.Container(
          color: PdfColors.white,
          child: _buildReceiptContent(trx),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4FC3F7);
    const dark = Color(0xFF0288D1);

    final totalTrx = TransactionService.history.length;
    final totalOmzet = TransactionService.history.fold<double>(
      0,
      (sum, e) => sum + e.total,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(fontSize: 13, color: Color(0xFF78909C)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AuthService.currentUser?.shopName ?? 'KasirApp',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primary, dark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Hero Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mulai Transaksi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekan tombol scan di bawah\nuntuk scan barcode produk',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats Row ──
            Row(
              children: [
                _StatCard(
                  label: 'Total Omzet',
                  value: _rp(totalOmzet),
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Transaksi',
                  value: '$totalTrx kali',
                  icon: Icons.receipt_long_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Stok Menipis ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stok Menipis (<10)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Product>>(
              future: DBService.getAllProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final lowStock = snapshot.data!
                    .where((p) => p.stock < 10)
                    .toList();

                if (lowStock.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Semua stok aman terjaga',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: lowStock.length,
                    itemBuilder: (context, i) {
                      final p = lowStock[i];
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFB71C1C),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Sisa ${p.stock}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            // ── Chart Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Traffic Transaksi Harian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '7 Hari',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0288D1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Chart ──
            Container(
              height: 240,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: const Color(0xFFECEFF1), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    // X-axis bottom: hari
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min',
                          ];
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[i],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF90A4AE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Y-axis left: jumlah transaksi
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF90A4AE),
                            ),
                          );
                        },
                      ),
                    ),
                    // Sembunyikan axis atas & kanan
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF0277BD),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toInt()} trx',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 2),
                        FlSpot(1, 3),
                        FlSpot(2, 2),
                        FlSpot(3, 5),
                        FlSpot(4, 4),
                        FlSpot(5, 7),
                        FlSpot(6, 5),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFF4FC3F7),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF0288D1),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4FC3F7).withValues(alpha: 0.25),
                            const Color(0xFF4FC3F7).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── History Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaksi Terakhir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
                if (TransactionService.history.isNotEmpty)
                  Text(
                    '${TransactionService.history.length} total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF90A4AE),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (TransactionService.history.isEmpty)
              _EmptyHistory()
            else
              ...TransactionService.history.take(5).map((e) {
                final isCash = e.method == 'CASH';
                return GestureDetector(
                  onTap: () => _showTrxDetail(context, e),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCash
                                ? const Color(
                                    0xFF43E97B,
                                  ).withValues(alpha: 0.15)
                                : const Color(
                                    0xFF4FC3F7,
                                  ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCash
                                ? Icons.payments_rounded
                                : Icons.qr_code_rounded,
                            size: 20,
                            color: isCash
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF0288D1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.method,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1A2340),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e.time,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF90A4AE),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _rp(e.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2340),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty History ──
class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada transaksi',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
