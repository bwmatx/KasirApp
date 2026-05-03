import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/user.dart';

class DBService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'kasir.db');

    return await openDatabase(
      path,
      version: 4, // 🔥 NAIK VERSION
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            barcode TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            category TEXT DEFAULT 'Umum',
            stock INTEGER DEFAULT 0
          )
        ''');
        await _createUsersTable(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE products ADD COLUMN category TEXT DEFAULT 'Umum'",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE products ADD COLUMN stock INTEGER DEFAULT 0",
          );
        }
        if (oldVersion < 4) {
          await _createUsersTable(db);
        }
      },
    );
  }

  static Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        username TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        dob TEXT NOT NULL,
        shopName TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
  }

  // 👤 USER OPERATIONS
  static Future<void> registerUser(UserModel user) async {
    final dbClient = await db;
    await dbClient.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<UserModel?> loginUser(String username, String password) async {
    final dbClient = await db;
    final result = await dbClient.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  static Future<void> updateUser(UserModel user) async {
    final dbClient = await db;
    await dbClient.update(
      'users',
      user.toMap(),
      where: 'username = ?',
      whereArgs: [user.username],
    );
  }

  // 📦 PRODUCT OPERATIONS
  static Future<Product?> getProduct(String barcode) async {
    final dbClient = await db;
    final result = await dbClient.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  static Future<List<Product>> getAllProducts() async {
    final dbClient = await db;
    final result = await dbClient.query('products');
    return result.map((e) => Product.fromMap(e)).toList();
  }

  static Future<void> insertProduct(Product product) async {
    final dbClient = await db;
    await dbClient.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteProduct(String barcode) async {
    final dbClient = await db;
    await dbClient.delete('products', where: 'barcode = ?', whereArgs: [barcode]);
  }

  static Future<void> updateProduct(String oldBarcode, Product product) async {
    final dbClient = await db;
    await dbClient.delete('products', where: 'barcode = ?', whereArgs: [oldBarcode]);
    await dbClient.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 🧹 CLEAR DATA
  static Future<void> clearAllProducts() async {
    final dbClient = await db;
    await dbClient.delete('products');
  }

  static Future<void> seedDummyData() async {
    // Kosongkan dummy data sesuai instruksi user untuk final build
  }
}
