import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

// === MODELOS DE DADOS ===

class Product {
  final int? id;
  final String name;
  final double price;
  final String imageUrl;

  static const String defaultImageUrl = 'assets/images/placeholder.png';

  Product({this.id, required this.name, required this.price, String? imageUrl})
      : imageUrl = imageUrl ?? defaultImageUrl;

  factory Product.fromMap(Map<String, dynamic> map) {
    final String? dbUrl = map['image_url'] as String?;
    final String finalUrl =
    (dbUrl == null || dbUrl.isEmpty) ? defaultImageUrl : dbUrl;

    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: finalUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': (imageUrl == defaultImageUrl) ? null : imageUrl,
    };
  }
}

class User {
  final int id;
  final String username;
  final String accessLevel;

  User({required this.id, required this.username, required this.accessLevel});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      accessLevel: map['access_level'] as String,
    );
  }
}

// === SERVIÇO DE BANCO DE DADOS ===

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _initDatabaseFactory();
  }

  Database? _database;

  void _initDatabaseFactory() {
    // 🌐 Se for Web
    if (kIsWeb) {
      // O sqflite_ffi_web deve estar configurado se você quiser usar no navegador
      print("🌐 Rodando no Flutter Web — banco local não suportado por sqflite.");
      return;
    }

    // 💻 Se for Desktop
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print("✅ SQFLite FFI inicializado.");
    } catch (e) {
      print("⚠️ Falha ao inicializar SQFLite FFI: $e");
    }
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'O SQLite local (sqflite) não é suportado no Flutter Web. '
            'Use IndexedDB ou Firebase Firestore para persistência Web.',
      );
    }

    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'course_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            access_level TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE favorite_item (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT,
            description TEXT,
            FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE shopping_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT,
            quantity INTEGER,
            FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE product (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price REAL,
            image_url TEXT
          )
        ''');
      },
    );
  }

  // =========================================================
  // AUTENTICAÇÃO
  // =========================================================

  Future<int> registerUser(
      String username, String password, String accessLevel) async {
    final db = await database;
    return await db.insert('user', {
      'username': username,
      'password': password,
      'access_level': accessLevel,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> loginUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // =========================================================
  // PRODUTOS
  // =========================================================

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('product', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('product');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    if (product.id == null) return 0;
    return await db.update('product', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('product', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================
  // FAVORITOS E LISTA DE COMPRAS
  // =========================================================

  Future<int> addFavoriteItem(
      int userId, String name, String description) async {
    final db = await database;
    return await db.insert('favorite_item', {
      'user_id': userId,
      'name': name,
      'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> getFavoriteItems(int userId) async {
    final db = await database;
    return db.query('favorite_item',
        where: 'user_id = ?', whereArgs: [userId]);
  }
}
