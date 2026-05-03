import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/db_service.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const primary = Color(0xFF4FC3F7);
  static const dark = Color(0xFF0288D1);

  List<Product> products = [];
  List<Product> filtered = [];

  String selectedCategory = 'Semua';
  String searchText = '';

  final searchController = TextEditingController();

  final categories = ['Semua', 'Umum', 'Makanan', 'Minuman', 'Snack', 'UMKM', 'Lainnya'];

  String _rp(num n) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(n);

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    final data = await DBService.getAllProducts();
    setState(() {
      products = data;
      _applyFilter();
    });
  }

  void _applyFilter() {
    filtered = products.where((p) {
      final matchCategory =
          selectedCategory == 'Semua' ? true : p.category == selectedCategory;
      final matchSearch =
          p.name.toLowerCase().contains(searchText.toLowerCase()) ||
          p.barcode.contains(searchText);
      return matchCategory && matchSearch;
    }).toList();

    // 🔥 Urutkan berdasarkan abjad (nama)
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _delete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBService.deleteProduct(product.barcode);
      loadProducts();
    }
  }

  void _updateStock(Product p, int delta) async {
    final newStock = p.stock + delta;
    if (newStock < 0) return;

    final updated = Product(
      barcode: p.barcode,
      name: p.name,
      price: p.price,
      category: p.category,
      stock: newStock,
    );
    await DBService.updateProduct(p.barcode, updated);
    loadProducts();
  }

  void _showStockInputDialog(Product p) {
    final stockC = TextEditingController(text: p.stock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Stok: ${p.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: stockC,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Jumlah Stok',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(stockC.text);
              if (val != null) {
                final updated = Product(
                  barcode: p.barcode,
                  name: p.name,
                  price: p.price,
                  category: p.category,
                  stock: val,
                );
                await DBService.updateProduct(p.barcode, updated);
                if (!mounted) return;
                Navigator.pop(context);
                loadProducts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _edit(Product product) {
    final nameC = TextEditingController(text: product.name);
    final priceC = TextEditingController(text: product.price.toString());
    final stockC = TextEditingController(text: product.stock.toString());
    final barcodeC = TextEditingController(text: product.barcode);

    showDialog(
      context: context,
      builder: (context) {
        String selectedCat = categories.contains(product.category) 
            ? product.category 
            : (product.category == 'Pabrik' ? 'Umum' : categories.firstWhere((c) => c != 'Semua', orElse: () => 'Umum'));

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Produk',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: barcodeC,
                      decoration: InputDecoration(
                        labelText: 'Barcode / Kode Produk',
                        prefixIcon: const Icon(Icons.qr_code, size: 20, color: dark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameC,
                      decoration: InputDecoration(
                        labelText: 'Nama Produk',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: categories
                          .where((c) => c != 'Semua')
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedCat = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final updated = Product(
                      barcode: barcodeC.text.trim(),
                      name: nameC.text.trim(),
                      price: double.tryParse(priceC.text) ?? 0,
                      category: selectedCat,
                      stock: int.tryParse(stockC.text) ?? 0,
                    );
                    await DBService.updateProduct(product.barcode, updated);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    loadProducts();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _goAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (result == true) loadProducts();
  }

  // icon per kategori
  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Makanan':
        return Icons.fastfood_rounded;
      case 'Minuman':
        return Icons.local_drink_rounded;
      case 'Snack':
        return Icons.cookie_rounded;
      case 'UMKM':
        return Icons.storefront_rounded;
      case 'Lainnya':
        return Icons.category_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        title: const Text(
          'Daftar Produk',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              '${filtered.length} item',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _goAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w600)),
      ),

      body: Column(
        children: [
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: TextField(
              controller: searchController,
              onChanged: (v) {
                searchText = v;
                setState(_applyFilter);
              },
              decoration: InputDecoration(
                hintText: 'Cari nama atau barcode...',
                hintStyle:
                    const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFFB0BEC5)),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFFB0BEC5), size: 18),
                        onPressed: () {
                          searchController.clear();
                          searchText = '';
                          setState(_applyFilter);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── Category chips ──
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final active = selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    selectedCategory = cat;
                    setState(_applyFilter);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
                            )
                          : null,
                      color: active ? null : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color:
                              active ? Colors.white : const Color(0xFF78909C),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Product list ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Produk tidak ditemukan',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_catIcon(p.category), size: 26, color: dark),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text(_rp(p.price), style: const TextStyle(color: dark, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(p.barcode, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  // Stock Controls
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F4F8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        _miniBtn(Icons.remove, () => _updateStock(p, -1)),
                                        InkWell(
                                          onTap: () => _showStockInputDialog(p),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Column(
                                              children: [
                                                const Text('Stok', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                Text('${p.stock}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        _miniBtn(Icons.add, () => _updateStock(p, 1)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _edit(p),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
                                          SizedBox(width: 6),
                                          Text('Edit', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 24, color: const Color(0xFFEEEEEE)),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _delete(p),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.delete_rounded, size: 16, color: Colors.redAccent),
                                          SizedBox(width: 6),
                                          Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)
          ],
        ),
        child: Icon(icon, size: 16, color: dark),
      ),
    );
  }
}
