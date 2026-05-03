import '../models/cart_item.dart';

class TransactionModel {
  final String time;
  final double total;
  final String method;
  final List<CartItem> items;
  final double uangBayar;
  final double kembalian;

  TransactionModel({
    required this.time,
    required this.total,
    required this.method,
    required this.items,
    this.uangBayar = 0,
    this.kembalian = 0,
  });
}

class TransactionService {
  static List<TransactionModel> history = [];

  static void add(TransactionModel trx) {
    history.insert(0, trx);
  }
}
