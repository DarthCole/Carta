import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/store.dart';
import '../models/category.dart';
import '../models/product.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'carta.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        barcode TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        restock_threshold INTEGER NOT NULL DEFAULT 10,
        price REAL NOT NULL DEFAULT 0.0,
        verified INTEGER NOT NULL DEFAULT 0,
        last_updated TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Seed stores
    final store1Id = await db.insert('stores', {
      'name': 'Downtown Mart',
      'address': '123 Main Street, Downtown',
      'phone': '+233 24 123 4567',
      'created_at': DateTime.now().toIso8601String(),
    });
    final store2Id = await db.insert('stores', {
      'name': 'Campus Corner Shop',
      'address': '45 University Ave',
      'phone': '+233 20 987 6543',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed categories for store 1
    final cat1Id = await db.insert('categories', {
      'store_id': store1Id,
      'name': 'Beverages',
      'description': 'Drinks, juices, water',
    });
    final cat2Id = await db.insert('categories', {
      'store_id': store1Id,
      'name': 'Snacks',
      'description': 'Chips, biscuits, cookies',
    });
    final cat3Id = await db.insert('categories', {
      'store_id': store1Id,
      'name': 'Personal Care',
      'description': 'Soap, shampoo, toiletries',
    });

    // Seed categories for store 2
    final cat4Id = await db.insert('categories', {
      'store_id': store2Id,
      'name': 'Stationery',
      'description': 'Notebooks, pens, supplies',
    });
    final cat5Id = await db.insert('categories', {
      'store_id': store2Id,
      'name': 'Beverages',
      'description': 'Drinks and water',
    });

    final now = DateTime.now().toIso8601String();
    // Seed products
    final products = [
      {'store_id': store1Id, 'category_id': cat1Id, 'name': 'Coca-Cola 500ml', 'brand': 'Coca-Cola', 'barcode': '5449000000996', 'quantity': 48, 'restock_threshold': 12, 'price': 5.0, 'verified': 1, 'last_updated': now},
      {'store_id': store1Id, 'category_id': cat1Id, 'name': 'Fanta Orange 500ml', 'brand': 'Coca-Cola', 'barcode': '5449000011527', 'quantity': 36, 'restock_threshold': 12, 'price': 5.0, 'verified': 1, 'last_updated': now},
      {'store_id': store1Id, 'category_id': cat1Id, 'name': 'Voltic Water 1.5L', 'brand': 'Voltic', 'barcode': '6001240100011', 'quantity': 5, 'restock_threshold': 10, 'price': 3.0, 'verified': 0, 'last_updated': now},
      {'store_id': store1Id, 'category_id': cat2Id, 'name': 'Pringles Original', 'brand': 'Pringles', 'barcode': '5053990101573', 'quantity': 20, 'restock_threshold': 8, 'price': 15.0, 'verified': 1, 'last_updated': now},
      {'store_id': store1Id, 'category_id': cat2Id, 'name': 'McVities Digestive', 'brand': 'McVities', 'barcode': '5000168001142', 'quantity': 3, 'restock_threshold': 6, 'price': 12.0, 'verified': 0, 'last_updated': now},
      {'store_id': store1Id, 'category_id': cat3Id, 'name': 'Dettol Soap', 'brand': 'Dettol', 'barcode': '6001106112233', 'quantity': 24, 'restock_threshold': 10, 'price': 8.0, 'verified': 1, 'last_updated': now},
      {'store_id': store2Id, 'category_id': cat4Id, 'name': 'A4 Notebook 120pg', 'brand': 'Campap', 'barcode': '9555042300011', 'quantity': 50, 'restock_threshold': 15, 'price': 7.0, 'verified': 1, 'last_updated': now},
      {'store_id': store2Id, 'category_id': cat4Id, 'name': 'BIC Cristal Pen', 'brand': 'BIC', 'barcode': '3086123100015', 'quantity': 2, 'restock_threshold': 20, 'price': 2.0, 'verified': 1, 'last_updated': now},
      {'store_id': store2Id, 'category_id': cat5Id, 'name': 'Sprite 500ml', 'brand': 'Coca-Cola', 'barcode': '5449000014535', 'quantity': 18, 'restock_threshold': 10, 'price': 5.0, 'verified': 0, 'last_updated': now},
    ];
    for (final p in products) {
      await db.insert('products', p);
    }
  }

  // ── Store CRUD ──
  Future<List<Store>> getStores() async {
    final db = await database;
    final maps = await db.query('stores', orderBy: 'name ASC');
    return maps.map((m) => Store.fromMap(m)).toList();
  }

  Future<Store> insertStore(Store store) async {
    final db = await database;
    final id = await db.insert('stores', store.toMap()..remove('id'));
    return store.copyWith(id: id);
  }

  Future<void> updateStore(Store store) async {
    final db = await database;
    await db.update('stores', store.toMap(), where: 'id = ?', whereArgs: [store.id]);
  }

  Future<void> deleteStore(int id) async {
    final db = await database;
    await db.delete('stores', where: 'id = ?', whereArgs: [id]);
  }

  // ── Category CRUD ──
  Future<List<Category>> getCategories(int storeId) async {
    final db = await database;
    final maps = await db.query('categories', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category> insertCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap()..remove('id'));
    return category.copyWith(id: id);
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── Product CRUD ──
  Future<List<Product>> getProducts(int storeId, {int? categoryId}) async {
    final db = await database;
    String where = 'store_id = ?';
    List<dynamic> args = [storeId];
    if (categoryId != null) {
      where += ' AND category_id = ?';
      args.add(categoryId);
    }
    final maps = await db.query('products', where: where, whereArgs: args, orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode, int storeId) async {
    final db = await database;
    final maps = await db.query('products', where: 'barcode = ? AND store_id = ?', whereArgs: [barcode, storeId]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> searchProducts(int storeId, {String? query, String? brand, int? categoryId}) async {
    final db = await database;
    String where = 'store_id = ?';
    List<dynamic> args = [storeId];
    if (categoryId != null) {
      where += ' AND category_id = ?';
      args.add(categoryId);
    }
    if (brand != null && brand.isNotEmpty) {
      where += ' AND brand = ?';
      args.add(brand);
    }
    if (query != null && query.isNotEmpty) {
      where += ' AND (name LIKE ? OR brand LIKE ? OR barcode LIKE ?)';
      final wildcard = '%$query%';
      args.addAll([wildcard, wildcard, wildcard]);
    }
    final maps = await db.query('products', where: where, whereArgs: args, orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<String>> getBrands(int storeId) async {
    final db = await database;
    final maps = await db.rawQuery('SELECT DISTINCT brand FROM products WHERE store_id = ? ORDER BY brand ASC', [storeId]);
    return maps.map((m) => m['brand'] as String).toList();
  }

  Future<Product> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', product.toMap()..remove('id'));
    return product.copyWith(id: id);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getLowStockProducts(int storeId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM products WHERE store_id = ? AND quantity <= restock_threshold ORDER BY quantity ASC',
      [storeId],
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> getProductCount(int storeId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM products WHERE store_id = ?', [storeId]);
    return result.first['cnt'] as int;
  }

  Future<int> getLowStockCount(int storeId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE store_id = ? AND quantity <= restock_threshold',
      [storeId],
    );
    return result.first['cnt'] as int;
  }
}
