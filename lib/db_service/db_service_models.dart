import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// === MODELOS DE DADOS ===

// Modelo para a tabela 'product'
class Product {
  final int? id;
  final String name;
  final double price;
  final String imageUrl;

  // 1. Definição do caminho da imagem local padrão
  // Você deve garantir que este asset esteja configurado no seu pubspec.yaml
  static const String defaultImageUrl = 'assets/images/placeholder.png';

  // 2. Construtor ajustado: imageUrl é opcional.
  Product({this.id, required this.name, required this.price, String? imageUrl})
  // Se imageUrl for nulo, usa o defaultImageUrl
      : this.imageUrl = imageUrl ?? defaultImageUrl;

  // Converte um Map (vindo do DB) para um objeto Product
  factory Product.fromMap(Map<String, dynamic> map) {
    // 3. Lógica para carregar a URL: se for null ou vazia no DB, usa o default
    final String? dbUrl = map['image_url'] as String?;
    final String finalUrl = (dbUrl == null || dbUrl.isEmpty) ? defaultImageUrl : dbUrl;

    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      // O preço é armazenado como REAL/DOUBLE no DB
      price: map['price'] as double,
      imageUrl: finalUrl,
    );
  }

  // Converte um objeto Product para um Map (para salvar no DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      // 4. Lógica para salvar: se a URL for a padrão, salva NULL no DB.
      'image_url': (imageUrl == defaultImageUrl) ? null : imageUrl,
    };
  }
}

// Modelo para a tabela 'user' (apenas para referência)
class User {
  final int id;
  final String username;
  final String accessLevel;
  // A senha não deve ser exposta no modelo após o login

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
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Usamos 'course_app.db' como nome do arquivo
    String path = join(await getDatabasesPath(), 'course_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabela 1: Usuários
        await db.execute('''
          CREATE TABLE user (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,         
            access_level TEXT      
          )
        ''');

        // Tabela 2: Itens Favoritos (Relacionamento N-para-1 com User)
        await db.execute('''
          CREATE TABLE favorite_item (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT,
            description TEXT,
            FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
          )
        ''');

        // Tabela 3: Lista de Compras (Relacionamento N-para-1 com User)
        await db.execute('''
          CREATE TABLE shopping_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT,
            quantity INTEGER,
            FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
          )
        ''');

        // Tabela 4 (NOVA): Produtos para a Tela Inicial
        // A coluna image_url é TEXT e permite NULL por padrão.
        await db.execute('''
          CREATE TABLE product (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price REAL,             -- Usamos REAL para números decimais
            image_url TEXT          -- URL da imagem (agora opcional)
          )
        ''');
      },
    );
  }

  // =========================================================
  // OPERAÇÕES DE AUTENTICAÇÃO
  // =========================================================

  /// Insere um novo usuário no banco de dados.
  Future<int> registerUser(String username, String password, String accessLevel) async {
    final db = await database;
    // Em um app real, use um hash seguro para a senha!
    return await db.insert('user', {
      'username': username,
      'password': password,
      'access_level': accessLevel,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Tenta logar um usuário. Retorna o mapa do usuário ou null.
  Future<User?> loginUser(String username, String password) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // Cria o objeto User (sem a senha)
      return User.fromMap(maps.first);
    }
    return null;
  }

  // =========================================================
  // OPERAÇÕES DE PRODUTOS (CRUD)
  // =========================================================

  /// Insere um novo produto no banco de dados.
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('product', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retorna todos os produtos do banco de dados.
  Future<List<Product>> getProducts() async {
    final db = await database;
    // Consulta todos os registros
    final List<Map<String, dynamic>> maps = await db.query('product');

    // Converte a lista de Map em uma lista de objetos Product
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  /// Atualiza um produto existente.
  Future<int> updateProduct(Product product) async {
    final db = await database;
    if (product.id == null) return 0; // Não pode atualizar sem ID

    return await db.update(
      'product',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Deleta um produto pelo ID.
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'product',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================
  // OPERAÇÕES DE FAVORITOS E LISTA DE COMPRAS (Exemplo)
  // =========================================================

  // Os métodos para Favorites e ShoppingList seguirão o mesmo padrão,
  // mas usando o 'user_id' como filtro (FK).

  /// Insere um item favorito vinculado a um usuário.
  Future<int> addFavoriteItem(int userId, String name, String description) async {
    final db = await database;
    return await db.insert('favorite_item', {
      'user_id': userId,
      'name': name,
      'description': description,
    });
  }

  /// Retorna os favoritos de um usuário específico.
  Future<List<Map<String, dynamic>>> getFavoriteItems(int userId) async {
    final db = await database;
    return db.query(
      'favorite_item',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
