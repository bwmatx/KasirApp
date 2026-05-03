import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/db_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const primary = Color(0xFF4FC3F7);
  static const dark = Color(0xFF0288D1);

  final _formKey = GlobalKey<FormState>();

  final barcodeC = TextEditingController();
  final nameC = TextEditingController();
  final priceC = TextEditingController();
  final stockC = TextEditingController(text: '0');

  String category = 'Umum';

  final categories = ['Umum', 'Makanan', 'Minuman', 'Snack', 'UMKM', 'Lainnya'];

  @override
  void dispose() {
    barcodeC.dispose();
    nameC.dispose();
    priceC.dispose();
    stockC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      barcode: barcodeC.text.trim(),
      name: nameC.text.trim(),
      price: double.tryParse(priceC.text.replaceAll(',', '')) ?? 0,
      category: category,
      stock: int.tryParse(stockC.text) ?? 0,
    );

    await DBService.insertProduct(product);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

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
          'Tambah Produk',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Informasi Produk'),
                    const SizedBox(height: 12),
                    _inputField(
                      controller: barcodeC,
                      label: 'Barcode',
                      icon: Icons.qr_code_rounded,
                      hint: 'Scan atau ketik barcode',
                    ),
                    const SizedBox(height: 10),
                    _inputField(
                      controller: nameC,
                      label: 'Nama Produk',
                      icon: Icons.label_rounded,
                      hint: 'Nama produk',
                    ),
                    const SizedBox(height: 10),
                    _inputField(
                      controller: priceC,
                      label: 'Harga',
                      icon: Icons.payments_rounded,
                      hint: '0',
                      number: true,
                      prefix: 'Rp ',
                    ),
                    const SizedBox(height: 10),
                    _inputField(
                      controller: stockC,
                      label: 'Stok Awal',
                      icon: Icons.inventory_2_rounded,
                      hint: '0',
                      number: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Kategori'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final active = category == cat;
                        return GestureDetector(
                          onTap: () => setState(() => category = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: active
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF29B6F6),
                                        Color(0xFF0277BD),
                                      ],
                                    )
                                  : null,
                              color: active ? null : const Color(0xFFF0F4F8),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF78909C),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    'Simpan Produk',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
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

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    bool number = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: Icon(icon, size: 20, color: dark),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
