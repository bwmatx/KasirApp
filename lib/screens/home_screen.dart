import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/product.dart';
import '../services/db_service.dart';
import '../services/cart_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const primary = Color(0xFF4FC3F7);

  final controller = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _scanAnim;
  final _manualCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  Future<void> _handleScan(String barcode) async {
    final product = await DBService.getProduct(barcode);

    if (product != null) {
      setState(() {
        CartService.addProduct(product);
      });
      _showMinimalPopup(product);
    } else {
      _showNotFoundSnack(barcode);
    }
  }

  void _showNotFoundSnack(String barcode) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF37474F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded,
                color: Colors.white54, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Barcode "$barcode" tidak ditemukan',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // POPUP saat produk ditemukan
  void _showMinimalPopup(Product product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Center(child: _MinimalPopup(product: product));
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  Future<void> _showUmkmPopup() async {
    final all = await DBService.getAllProducts();
    final umkms = all.where((p) => p.category == 'UMKM').toList();
    if (umkms.isEmpty) {
      _showNotFoundSnack('UMKM dummy belum disiapkan');
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _UmkmSheet(
          umkms: umkms,
          onSelect: (product) {
            Navigator.pop(context);
            _handleScan(product.barcode);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    controller.dispose();
    _manualCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 📷 Kamera
          Positioned.fill(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) async {
                if (_isProcessing) return;

                final code = capture.barcodes.first.rawValue;
                if (code == null) return;

                _isProcessing = true;
                await _handleScan(code);
                await Future.delayed(const Duration(milliseconds: 900));
                _isProcessing = false;
              },
            ),
          ),

          // Overlay gelap cutout
          Positioned.fill(child: CustomPaint(painter: _Overlay())),

          // UI overlay atas
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Tombol kembali
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Scan Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // Cart indicator
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart_rounded,
                                  color: primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${CartService.cart.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scan area border dengan corner marks
          Center(
            child: SizedBox(
              width: 300,
              height: 120,
              child: Stack(
                children: [
                  // Border utama (transparan, hanya corner marks yg terlihat)
                  ..._corners(),

                  // Scan line animasi
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (_, __) {
                      return Align(
                        alignment: Alignment(0, _scanAnim.value * 2 - 1),
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                primary,
                                primary,
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Label bawah scan area
          Center(
            child: Transform.translate(
              offset: const Offset(0, 80),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arahkan kamera ke barcode produk',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),

          // ── List Scanned Items & Lanjut Bayar ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 290,
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Manual Input Row ──
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCodeCtrl,
                          decoration: InputDecoration(
                            hintText: 'Kode Manual...',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_manualCodeCtrl.text.isNotEmpty) {
                            _handleScan(_manualCodeCtrl.text);
                            _manualCodeCtrl.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _showUmkmPopup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('UMKM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text('Barang Terscan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2340))),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CartService.cart.isEmpty 
                    ? const Center(child: Text('Belum ada barang terscan', style: TextStyle(color: Colors.grey, fontSize: 13))) 
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: CartService.cart.length,
                        itemBuilder: (context, i) {
                          final item = CartService.cart[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A2340)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Text('${item.quantity} x Rp ${item.product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF0288D1), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: CartService.cart.isEmpty ? null : () {
                      Navigator.pop(context, 'cart');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text('Lanjut Bayar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Corner marks untuk scan area
  List<Widget> _corners() {
    const len = 22.0;
    const thick = 3.0;
    const r = 6.0;
    const c = primary;

    return [
      // Top-left
      Positioned(
        top: 0, left: 0,
        child: _corner(top: true, left: true, len: len, thick: thick, r: r, c: c),
      ),
      // Top-right
      Positioned(
        top: 0, right: 0,
        child: _corner(top: true, left: false, len: len, thick: thick, r: r, c: c),
      ),
      // Bottom-left
      Positioned(
        bottom: 0, left: 0,
        child: _corner(top: false, left: true, len: len, thick: thick, r: r, c: c),
      ),
      // Bottom-right
      Positioned(
        bottom: 0, right: 0,
        child: _corner(top: false, left: false, len: len, thick: thick, r: r, c: c),
      ),
    ];
  }

  Widget _corner({
    required bool top,
    required bool left,
    required double len,
    required double thick,
    required double r,
    required Color c,
  }) {
    return SizedBox(
      width: len,
      height: len,
      child: CustomPaint(
        painter: _CornerPainter(
            top: top, left: left, thick: thick, radius: r, color: c),
      ),
    );
  }
}

// Corner painter
class _CornerPainter extends CustomPainter {
  final bool top, left;
  final double thick, radius;
  final Color color;

  const _CornerPainter({
    required this.top,
    required this.left,
    required this.thick,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double x = left ? size.width : 0;
    final double y = top ? size.height : 0;
    final double dx = left ? -1 : 1;
    final double dy = top ? -1 : 1;

    final path = Path()
      ..moveTo(x, y + dy * radius)
      ..lineTo(x, y)
      ..lineTo(x + dx * radius, y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter o) => false;
}

// POPUP produk ditemukan
class _MinimalPopup extends StatelessWidget {
  final Product product;
  const _MinimalPopup({required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2340)),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Rp ${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0288D1),
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '✓ Ditambahkan ke keranjang',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// Overlay cutout
class _Overlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final hole = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 300,
      height: 120,
    );

    final path = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ── Sheet UMKM ──
class _UmkmSheet extends StatefulWidget {
  final List<Product> umkms;
  final ValueChanged<Product> onSelect;
  const _UmkmSheet({required this.umkms, required this.onSelect});

  @override
  State<_UmkmSheet> createState() => _UmkmSheetState();
}

class _UmkmSheetState extends State<_UmkmSheet> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.umkms.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Pilih Produk UMKM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2340))),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari nama atau kode produk...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              fillColor: const Color(0xFFF0F4F8),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: filtered.isEmpty 
              ? const Center(child: Text('Tidak ditemukan', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final p = filtered[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF57C00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFFF57C00)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(p.barcode, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Text('Rp ${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0288D1))),
                  onTap: () => widget.onSelect(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

