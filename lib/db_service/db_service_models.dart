import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'carrinho_model.dart'; // Assumindo que este arquivo contém o CarrinhoModel

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
    final String finalUrl = (dbUrl == null || dbUrl.isEmpty)
        ? defaultImageUrl
        : dbUrl;

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
      print(
        "🌐 Rodando no Flutter Web — banco local não suportado por sqflite.",
      );
      return;
    }

    // 💻 Se for Desktop (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print("✅ SQFLite FFI inicializado para desktop.");
      } catch (e) {
        print("⚠️ Falha ao inicializar SQFLite FFI: $e");
      }
    } else {
      // 📱 Para Android e iOS, usa o sqflite padrão
      print("✅ SQFLite nativo inicializado para Android/iOS.");
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

    // ⭐ MUDANÇA CRÍTICA 1: Novo nome para forçar recriação limpa
    final path = join(dbPath, 'course_app_v3.db');

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
            product_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
            UNIQUE (user_id, product_id)
          )
        ''');

        // ⭐ MUDANÇA CRÍTICA 2: Apenas uma definição da shopping_list com 'price'
        await db.execute('''
          CREATE TABLE shopping_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT,
            quantity INTEGER,
            price REAL, -- CAMPO 'price' AGORA PRESENTE
            image_url TEXT,
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
    String username,
    String password,
    String accessLevel,
  ) async {
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
    return await db.insert(
      'product',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('product');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    if (product.id == null) return 0;
    return await db.update(
      'product',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('product', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================
  // FAVORITOS
  // =========================================================

  //Adiciona um produto aos favoritos
  Future<int> addProductToFavorites(int userId, int productId) async {
    final db = await database;
    return await db.insert(
      'favorite_item',
      {'user_id': userId, 'product_id': productId},
      // Ignora se já existir
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  //Remove um produto dos favoritos
  Future<int> removeProductFromFavorites(int userId, int productId) async {
    final db = await database;
    return await db.delete(
      'favorite_item',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }

  //Verifica se um produto está favoritado por um usuário
  Future<bool> isProductFavorite(int userId, int productId) async {
    final db = await database;
    final maps = await db.query(
      'favorite_item',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  //Retorna a lista completa de objetos Product favoritados por um usuário
  Future<List<Product>> getFavoriteProducts(int userId) async {
    final favoriteProductIds = await getFavoriteProductIds(userId);

    if (favoriteProductIds.isEmpty) {
      return [];
    }

    final db = await database;

    // Converte a lista de IDs em uma string para a cláusula WHERE (ex: '1, 5, 10')
    final idsInString = favoriteProductIds.join(',');

    // Busca os produtos cujos IDs estão na lista de favoritos
    final List<Map<String, dynamic>> maps = await db.query(
      'product',
      where: 'id IN ($idsInString)',
    );

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // =========================================================
  // LISTA DE COMPRAS (CARRINHO) - USANDO CarrinhoModel
  // =========================================================

  Future<void> addToShoppingList(
    int userId,
    String productName,
    double price,
    int quantity,
    String? imageUrl,
  ) async {
    final db = await database;

    //Tenta encontrar um item existente com o mesmo nome para o usuário
    final existingItem = await db.query(
      'shopping_list',
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, productName],
    );

    if (existingItem.isNotEmpty) {
      // Se existe, ATUALIZA A QUANTIDADE
      final currentQuantity = existingItem.first['quantity'] as int;
      final itemId = existingItem.first['id'] as int;
      await db.update(
        'shopping_list',
        {
          'quantity': currentQuantity + quantity,
          'image_url': imageUrl ?? existingItem.first['image_url'],
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );
    } else {
      //Se não existe, insere um novo item
      await db.insert('shopping_list', {
        'user_id': userId,
        'name': productName,
        'quantity': quantity,
        'price': price, // Novo campo
        'image_url': imageUrl, // SALVA A IMAGEM
      });
    }
  }

  // Retorna a lista de itens do carrinho
  Future<List<CarrinhoModel>> getShoppingList(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_list',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    // Usa CarrinhoModel.fromMap
    // O CarrinhoModel deve ser capaz de mapear o campo 'price'
    return List.generate(maps.length, (i) => CarrinhoModel.fromMap(maps[i]));
  }

  // Atualiza um item específico do carrinho
  Future<int> updateShoppingListItem(CarrinhoModel item) async {
    final db = await database;
    if (item.id == null) return 0;
    // Usa item.toMap() do CarrinhoModel
    return await db.update(
      'shopping_list',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Remove um item pelo seu ID na tabela
  Future<int> removeShoppingListItem(int itemId) async {
    final db = await database;
    return await db.delete(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // Limpa todo o carrinho do usuário
  Future<int> clearShoppingList(int userId) async {
    final db = await database;
    return await db.delete(
      'shopping_list',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // MÉTODO ORIGINAL (DEIXADO POR COMPATIBILIDADE)
  Future<int> addFavoriteItem(
    int userId,
    String name,
    String description,
  ) async {
    return 0;
  }

  // Este método agora retorna os IDs dos produtos favoritos
  Future<List<int>> getFavoriteProductIds(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_item',
      columns: ['product_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => maps[i]['product_id'] as int);
  }
}
