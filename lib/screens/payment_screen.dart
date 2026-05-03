import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../services/cart_service.dart';
import '../services/transaction_service.dart';
import '../models/product.dart';
import '../services/db_service.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  const PaymentScreen({super.key, required this.total});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const primary = Color(0xFF4FC3F7);
  static const dark = Color(0xFF0288D1);

  String method = 'CASH';
  DateTime now = DateTime.now();
  final phoneController = TextEditingController();
  final uangBayarController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    phoneController.dispose();
    uangBayarController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────
  String _rp(num n) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(n);

  String _formatPhone(String input) {
    String phone = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
    return phone;
  }

  // ── Contact picker ────────────────────────────────
  Future<void> _pickContact() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return;
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null && contact.phones.isNotEmpty) {
      phoneController.text = contact.phones.first.number;
    }
  }

  // ── PDF builder ───────────────────────────────────
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

  Future<pw.Document> _buildPdf() async {
    final doc = pw.Document();

    double bayar = widget.total;
    if (method == 'CASH') {
      final text = uangBayarController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        bayar = double.tryParse(text) ?? widget.total;
      }
    }
    final double kembali = bayar - widget.total;

    final styleBase = const pw.TextStyle(fontSize: 10);
    final styleBold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('PESANAN', style: styleBase)),
              if (phoneController.text.isNotEmpty)
                pw.Center(child: pw.Text('No Telp ${phoneController.text}', style: styleBase)),
              _dashedDivider(),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 60, child: pw.Text('Pelanggan', style: styleBase)),
                  pw.Text(' : Umum', style: styleBase),
                ]
              ),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 60, child: pw.Text('Waktu', style: styleBase)),
                  pw.Text(' : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}', style: styleBase),
                ]
              ),
              pw.Text('Struk Pesanan', style: styleBase),
              pw.Text('Take Away', style: styleBase),
              _dashedDivider(),
              ...CartService.cart.asMap().entries.map((entry) {
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
                          child: pw.Text('${e.quantity} x ${_rp(e.product.price)}', style: styleBase),
                        ),
                        pw.Text(_rp(sub), style: styleBase),
                      ]
                    )
                  ]
                );
              }),
              _dashedDivider(),
              pw.Text('Total QTY : ${CartService.cart.fold<int>(0, (p, c) => p + c.quantity)}', style: styleBase),
              _dashedDivider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Sub Total', style: styleBase), pw.Text(_rp(widget.total), style: styleBase)],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Total', style: styleBold), pw.Text(_rp(widget.total), style: styleBold)],
              ),
              if (method == 'CASH') ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('Bayar', style: styleBase), pw.Text(_rp(bayar), style: styleBase)],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('Kembali', style: styleBase), pw.Text(_rp(kembali > 0 ? kembali : 0), style: styleBase)],
                ),
              ],
              _dashedDivider(),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Bukan Bukti Pembayaran', style: styleBase)),
              pw.Center(child: pw.Text('Terimakasih Telah Berbelanja di', style: styleBase)),
              pw.Center(child: pw.Text('Toko Kami', style: styleBase)),
            ],
          ),
        ),
      ),
    );
    return doc;
  }

  Future<void> _printPdf() async {
    final doc = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  // ── Send Image (WhatsApp) ────────────
  Future<void> _sendImageWA() async {
    final phone = _formatPhone(phoneController.text);
    if (phone.isEmpty) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/struk.png');
    final doc = await _buildPdf();
    final bytes = await doc.save();
    
    await for (var page in Printing.raster(bytes, pages: [0], dpi: 200)) {
      final image = await page.toPng();
      await file.writeAsBytes(image);
      break;
    }

    try {
      const platform = MethodChannel('com.example.kasir_app/share');
      await platform.invokeMethod('shareToWhatsApp', {
        'phone': phone,
        'filePath': file.path,
        'text': 'Berikut adalah struk pembayaran Anda.',
      });
    } catch (e) {
      debugPrint('Error sharing to WhatsApp: $e');
    }
  }

  // ── Pay dialog ────────────────────────────────────
  void _pay() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          double bayar = widget.total;
          if (method == 'CASH') {
            final text = uangBayarController.text.replaceAll(RegExp(r'[^0-9]'), '');
            if (text.isNotEmpty) {
              bayar = double.tryParse(text) ?? 0;
            } else {
              bayar = 0;
            }
          }
          final bool isKurang = method == 'CASH' && bayar < widget.total;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Dialog header ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BW STORE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm:ss').format(now),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Total & method ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF1A2340),
                                ),
                              ),
                              Text(
                                _rp(widget.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: dark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (method == 'CASH') ...[
                            TextField(
                              controller: uangBayarController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              onChanged: (val) {
                                setDialogState(() {}); // trigger re-render
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Nominal Bayar',
                                labelStyle: const TextStyle(
                                    fontSize: 13, color: Color(0xFF90A4AE)),
                                prefixIcon: const Icon(Icons.payments_rounded,
                                    color: primary, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF0F4F8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                            ),
                            if (isKurang)
                              const Padding(
                                padding: EdgeInsets.only(top: 6, left: 12),
                                child: Text('Nominal kurang!', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                              ),
                            const SizedBox(height: 16),
                          ],

                          // ── WhatsApp number input ──
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
                                        fontSize: 13, color: Color(0xFF90A4AE)),
                                    prefixIcon: const Icon(Icons.chat_rounded,
                                        color: Color(0xFF25D366), size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF0F4F8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: primary, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Kontak picker button
                              GestureDetector(
                                onTap: _pickContact,
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.contacts_rounded,
                                      color: dark, size: 22),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Action buttons ──
                          _dialogBtn(
                            label: isKurang ? 'Nominal Kurang' : 'Kirim ke WhatsApp',
                            icon: isKurang ? Icons.error_outline : Icons.chat_rounded,
                            color: isKurang ? Colors.grey : const Color(0xFF25D366),
                            onTap: isKurang ? () {} : _sendImageWA,
                          ),
                          const SizedBox(height: 8),
                          _dialogBtn(
                            label: isKurang ? 'Nominal Kurang' : 'Print PDF',
                            icon: isKurang ? Icons.error_outline : Icons.print_rounded,
                            color: isKurang ? Colors.grey : primary,
                            onTap: isKurang ? () {} : _printPdf,
                          ),
                          const SizedBox(height: 8),
                          _dialogBtn(
                            label: isKurang ? 'Nominal Kurang' : 'Selesai',
                            icon: isKurang ? Icons.error_outline : Icons.check_circle_rounded,
                            color: isKurang ? Colors.grey : dark,
                            onTap: isKurang ? () {} : () async {
                              // 🔥 Kurangi Stok di Database
                              for (var item in CartService.cart) {
                                final p = await DBService.getProduct(item.product.barcode);
                                if (p != null) {
                                  final updated = Product(
                                    barcode: p.barcode,
                                    name: p.name,
                                    price: p.price,
                                    category: p.category,
                                    stock: (p.stock - item.quantity).clamp(0, 999999),
                                  );
                                  await DBService.updateProduct(p.barcode, updated);
                                }
                              }

                              final bayarRaw = uangBayarController.text.replaceAll('.', '');
                              final bayarNum = double.tryParse(bayarRaw) ?? 0;
                              
                              TransactionService.add(
                                TransactionModel(
                                  time: now.toString(),
                                  total: widget.total,
                                  method: method,
                                  items: List.from(CartService.cart),
                                  uangBayar: bayarNum,
                                  kembalian: bayarNum - widget.total,
                                ),
                              );
                              CartService.cart.clear();
                              if (!mounted) return;
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(height: 8),
                          // Batal button (outlined)
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xFFCFD8DC)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF90A4AE),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // ── Main build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          // Jam real-time di AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                DateFormat('HH:mm:ss').format(now),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Total card ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
              child: Column(
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rp(widget.total),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    DateFormat('dd MMM yyyy  •  HH:mm:ss').format(now),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Metode pembayaran ──
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF90A4AE),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _methodBtn('CASH', Icons.payments_rounded),
                const SizedBox(width: 12),
                _methodBtn('QRIS', Icons.qr_code_rounded),
              ],
            ),

            const Spacer(),

            // ── Bayar button ──
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded, size: 22),
                label: const Text(
                  'Bayar Sekarang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Method selector ───────────────────────────────
  Widget _methodBtn(String m, IconData icon) {
    final active = method == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => method = m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: active ? Colors.white : const Color(0xFF90A4AE),
              ),
              const SizedBox(height: 6),
              Text(
                m,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF546E7A),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog action button ──────────────────────────
  Widget _dialogBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 46),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    final double value = double.tryParse(digits) ?? 0;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final String newText = formatter.format(value).trim();

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
