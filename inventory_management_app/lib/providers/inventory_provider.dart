import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class InventoryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();

  List<Store> _stores = [];
  List<Category> _categories = [];
  List<Product> _products = [];
  List<String> _brands = [];

  Store? _selectedStore;
  Category? _selectedCategory;
  String? _selectedBrand;
  String _searchQuery = '';

  List<Store> get stores => _stores;
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<String> get brands => _brands;
  Store? get selectedStore => _selectedStore;
  Category? get selectedCategory => _selectedCategory;
  String? get selectedBrand => _selectedBrand;
  String get searchQuery => _searchQuery;

  Future<void> loadStores() async {
    _stores = await _db.getStores();
    notifyListeners();
  }

  void selectStore(Store store) {
    _selectedStore = store;
    _selectedCategory = null;
    _selectedBrand = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadCategories() async {
    if (_selectedStore == null) return;
    _categories = await _db.getCategories(_selectedStore!.id!);
    notifyListeners();
  }

  Future<void> loadBrands() async {
    if (_selectedStore == null) return;
    _brands = await _db.getBrands(_selectedStore!.id!);
    notifyListeners();
  }

  Future<void> loadProducts() async {
    if (_selectedStore == null) return;
    _products = await _db.searchProducts(
      _selectedStore!.id!,
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      brand: _selectedBrand,
      categoryId: _selectedCategory?.id,
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts();
  }

  void setSelectedCategory(Category? category) {
    _selectedCategory = category;
    loadProducts();
  }

  void setSelectedBrand(String? brand) {
    _selectedBrand = brand;
    loadProducts();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedBrand = null;
    _searchQuery = '';
    loadProducts();
  }

  // ── Store management ──
  Future<void> addStore(String name, String address, String? phone) async {
    final store = Store(name: name, address: address, phone: phone);
    await _db.insertStore(store);
    await loadStores();
  }

  Future<void> editStore(Store store) async {
    await _db.updateStore(store);
    await loadStores();
  }

  Future<void> removeStore(int id) async {
    await _db.deleteStore(id);
    await loadStores();
  }

  // ── Category management ──
  Future<void> addCategory(String name, String? description) async {
    if (_selectedStore == null) return;
    final cat = Category(storeId: _selectedStore!.id!, name: name, description: description);
    await _db.insertCategory(cat);
    await loadCategories();
  }

  Future<void> editCategory(Category category) async {
    await _db.updateCategory(category);
    await loadCategories();
  }

  Future<void> removeCategory(int id) async {
    await _db.deleteCategory(id);
    await loadCategories();
    await loadProducts();
  }

  // ── Product management ──
  Future<void> addProduct(Product product) async {
    await _db.insertProduct(product);
    await loadProducts();
    await loadBrands();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    // Check if restock notification is needed
    if (product.needsRestock && _selectedStore != null) {
      await _notifications.showRestockAlert(
        _selectedStore!.name,
        product.name,
        product.quantity,
      );
    }
    await loadProducts();
  }

  Future<void> updateProductQuantity(Product product, int newQuantity) async {
    final updated = product.copyWith(quantity: newQuantity);
    await updateProduct(updated);
  }

  Future<void> removeProduct(int id) async {
    await _db.deleteProduct(id);
    await loadProducts();
    await loadBrands();
  }

  // ── Barcode scanning ──
  Future<Product?> lookupBarcode(String barcode) async {
    if (_selectedStore == null) return null;
    return await _db.getProductByBarcode(barcode, _selectedStore!.id!);
  }

  Future<void> verifyProduct(Product product, bool verified) async {
    final updated = product.copyWith(verified: verified);
    await _db.updateProduct(updated);
    await _notifications.showVerificationResult(product.name, verified);
    await loadProducts();
  }

  // ── Stats ──
  Future<int> getProductCount() async {
    if (_selectedStore == null) return 0;
    return await _db.getProductCount(_selectedStore!.id!);
  }

  Future<int> getLowStockCount() async {
    if (_selectedStore == null) return 0;
    return await _db.getLowStockCount(_selectedStore!.id!);
  }

  Future<List<Product>> getLowStockProducts() async {
    if (_selectedStore == null) return [];
    return await _db.getLowStockProducts(_selectedStore!.id!);
  }

  Future<void> checkAndNotifyLowStock() async {
    if (_selectedStore == null) return;
    final lowStock = await _db.getLowStockProducts(_selectedStore!.id!);
    for (final product in lowStock) {
      await _notifications.showRestockAlert(
        _selectedStore!.name,
        product.name,
        product.quantity,
      );
    }
  }
}
