import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/store.dart';
import '../models/category.dart';
import '../models/product.dart';

/// handling all sqlite database operations for the carta app.
///
/// implementing the singleton pattern to ensure only one database
/// connection exists throughout the app's lifecycle. managing crud
/// operations for stores, categories, and products, as well as
/// seeding initial demo data on first launch.
class DatabaseService {
  // singleton instance — ensuring a single shared database connection
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database; // caching the database reference after first initialisation

  /// getting the database instance, initialising it on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// opening (or creating) the sqlite database file at the app's data directory.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'carta.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// creating the database schema on first launch.
  /// defining three tables (stores, categories, products) with foreign key
  /// constraints and cascade deletes, then seeding sample data.
  Future<void> _onCreate(Database db, int version) async {
    // creating the stores table
    await db.execute('''
      CREATE TABLE stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // creating the categories table with a foreign key to stores
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
      )
    ''');

    // creating the products table with foreign keys to both stores and categories
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

    // populating the database with demo data for first-time users
    await _seedData(db);
  }

  /// inserting sample stores, categories, and products into the database.
  /// providing realistic test data so the app is usable right after install.
  /// some products are intentionally below their restock threshold to
  /// demonstrate the low-stock alert system.
  Future<void> _seedData(Database db) async {
    // seeding two sample stores
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

    // seeding categories for store 1 (downtown mart)
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

    // seeding categories for store 2 (campus corner shop)
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

    // seeding products across both stores with varied stock levels
    // note: voltic water, mcvities, and bic pen are intentionally low-stock
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

    // inserting each product row into the database
    for (final p in products) {
      await db.insert('products', p);
    }
  }

  // ── store crud operations ──

  /// fetching all stores sorted alphabetically by name.
  Future<List<Store>> getStores() async {
    final db = await database;
    final maps = await db.query('stores', orderBy: 'name ASC');
    return maps.map((m) => Store.fromMap(m)).toList();
  }

  /// inserting a new store and returning it with the auto-generated id.
  Future<Store> insertStore(Store store) async {
    final db = await database;
    final id = await db.insert('stores', store.toMap()..remove('id'));
    return store.copyWith(id: id);
  }

  /// updating an existing store's fields by its id.
  Future<void> updateStore(Store store) async {
    final db = await database;
    await db.update('stores', store.toMap(), where: 'id = ?', whereArgs: [store.id]);
  }

  /// deleting a store by id. cascade-deleting its categories and products.
  Future<void> deleteStore(int id) async {
    final db = await database;
    await db.delete('stores', where: 'id = ?', whereArgs: [id]);
  }

  // ── category crud operations ──

  /// fetching all categories for a given store, sorted alphabetically.
  Future<List<Category>> getCategories(int storeId) async {
    final db = await database;
    final maps = await db.query('categories', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  /// inserting a new category and returning it with the auto-generated id.
  Future<Category> insertCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap()..remove('id'));
    return category.copyWith(id: id);
  }

  /// updating an existing category's fields by its id.
  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  /// deleting a category by id. cascade-deleting its products.
  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── product crud operations ──

  /// fetching products for a store, optionally filtering by category.
  Future<List<Product>> getProducts(int storeId, {int? categoryId}) async {
    final db = await database;
    String where = 'store_id = ?';
    List<dynamic> args = [storeId];

    // appending category filter if provided
    if (categoryId != null) {
      where += ' AND category_id = ?';
      args.add(categoryId);
    }
    final maps = await db.query('products', where: where, whereArgs: args, orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// looking up a product by its barcode within a specific store.
  /// returning null if no match is found.
  Future<Product?> getProductByBarcode(String barcode, int storeId) async {
    final db = await database;
    final maps = await db.query('products', where: 'barcode = ? AND store_id = ?', whereArgs: [barcode, storeId]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  /// searching products with combined filters: text query, brand, and category.
  /// the text query matching against name, brand, and barcode using like.
  Future<List<Product>> searchProducts(int storeId, {String? query, String? brand, int? categoryId}) async {
    final db = await database;
    String where = 'store_id = ?';
    List<dynamic> args = [storeId];

    // building the where clause dynamically based on active filters
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
      final wildcard = '%$query%'; // wrapping in wildcards for partial matching
      args.addAll([wildcard, wildcard, wildcard]);
    }
    final maps = await db.query('products', where: where, whereArgs: args, orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// fetching a distinct list of brands available in a store for filter chips.
  Future<List<String>> getBrands(int storeId) async {
    final db = await database;
    final maps = await db.rawQuery('SELECT DISTINCT brand FROM products WHERE store_id = ? ORDER BY brand ASC', [storeId]);
    return maps.map((m) => m['brand'] as String).toList();
  }

  /// inserting a new product and returning it with the auto-generated id.
  Future<Product> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', product.toMap()..remove('id'));
    return product.copyWith(id: id);
  }

  /// updating an existing product's fields by its id.
  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  /// deleting a product by its id.
  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// fetching all products in a store whose quantity is at or below
  /// their restock threshold, sorted by quantity ascending (most urgent first).
  Future<List<Product>> getLowStockProducts(int storeId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM products WHERE store_id = ? AND quantity <= restock_threshold ORDER BY quantity ASC',
      [storeId],
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// counting the total number of products in a store.
  Future<int> getProductCount(int storeId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM products WHERE store_id = ?', [storeId]);
    return result.first['cnt'] as int;
  }

  /// counting products that are at or below their restock threshold.
  Future<int> getLowStockCount(int storeId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE store_id = ? AND quantity <= restock_threshold',
      [storeId],
    );
    return result.first['cnt'] as int;
  }
}
