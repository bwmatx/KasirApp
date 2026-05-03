class Product {
  final String barcode;
  final String name;
  final double price;
  final String category;
  final int stock; // 📦 NEW: Stok produk

  Product({
    required this.barcode,
    required this.name,
    required this.price,
    required this.category,
    this.stock = 0, // Default 0
  });

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'price': price,
      'category': category,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      barcode: map['barcode'].toString(),
      name: map['name'].toString(),
      price: (map['price'] as num).toDouble(),
      category: map['category']?.toString() ?? "Umum",
      stock: (map['stock'] as int?) ?? 0,
    );
  }
}
