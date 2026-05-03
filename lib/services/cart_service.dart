import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  static final List<CartItem> _cart = [];

  static List<CartItem> get cart => _cart;

  static void addProduct(Product product) {
    final index = _cart.indexWhere((e) => e.product.barcode == product.barcode);

    if (index != -1) {
      _cart[index].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
  }

  static void decrease(Product product) {
    final index = _cart.indexWhere((e) => e.product.barcode == product.barcode);

    if (index != -1) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    }
  }

  static double get total {
    return _cart.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }
}
