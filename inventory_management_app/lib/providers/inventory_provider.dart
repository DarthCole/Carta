import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../models/category.dart' as models; // aliasing to avoid conflict with flutter's built-in category
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// centralised state management for the carta inventory app.
///
/// extending changenotifier to provide reactive state updates to all
/// listening widgets. coordinating between the database service and
/// notification service, managing the currently selected store, active
/// filters, and all loaded data lists. this is the single source of
/// truth for the app's ui state.
class InventoryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService(); // database operations handler
  final NotificationService _notifications = NotificationService(); // notification dispatcher

  // ── state fields ──

  List<Store> _stores = []; // all stores loaded from the database
  List<models.Category> _categories = []; // categories for the selected store
  List<Product> _products = []; // products matching current filters
  List<String> _brands = []; // distinct brand names for filter chips

  Store? _selectedStore; // the store currently being viewed
  models.Category? _selectedCategory; // active category filter (null = all)
  String? _selectedBrand; // active brand filter (null = all)
  String _searchQuery = ''; // current text search query

  // ── getters exposing state to the ui ──

  List<Store> get stores => _stores;
  List<models.Category> get categories => _categories;
  List<Product> get products => _products;
  List<String> get brands => _brands;
  Store? get selectedStore => _selectedStore;
  models.Category? get selectedCategory => _selectedCategory;
  String? get selectedBrand => _selectedBrand;
  String get searchQuery => _searchQuery;

  // ── store loading and selection ──

  /// loading all stores from the database and notifying listeners.
  Future<void> loadStores() async {
    _stores = await _db.getStores();
    notifyListeners();
  }

  /// selecting a store and resetting all filters for a fresh start.
  void selectStore(Store store) {
    _selectedStore = store;
    _selectedCategory = null;
    _selectedBrand = null;
    _searchQuery = '';
    notifyListeners();
  }

  // ── category and brand loading ──

  /// loading categories for the currently selected store.
  Future<void> loadCategories() async {
    if (_selectedStore == null) return;
    _categories = await _db.getCategories(_selectedStore!.id!);
    notifyListeners();
  }

  /// loading distinct brand names for the selected store's filter chips.
  Future<void> loadBrands() async {
    if (_selectedStore == null) return;
    _brands = await _db.getBrands(_selectedStore!.id!);
    notifyListeners();
  }

  // ── product loading with filters ──

  /// loading products applying all active filters (search, brand, category).
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

  /// updating the search query and reloading filtered products.
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts();
  }

  /// setting or clearing the category filter and reloading products.
  void setSelectedCategory(models.Category? category) {
    _selectedCategory = category;
    loadProducts();
  }

  /// setting or clearing the brand filter and reloading products.
  void setSelectedBrand(String? brand) {
    _selectedBrand = brand;
    loadProducts();
  }

  /// clearing all active filters and reloading the full product list.
  void clearFilters() {
    _selectedCategory = null;
    _selectedBrand = null;
    _searchQuery = '';
    loadProducts();
  }

  // ── store management ──

  /// adding a new store to the database and refreshing the store list.
  Future<void> addStore(String name, String address, String? phone) async {
    final store = Store(name: name, address: address, phone: phone);
    await _db.insertStore(store);
    await loadStores();
  }

  /// updating an existing store's details and refreshing the list.
  Future<void> editStore(Store store) async {
    await _db.updateStore(store);
    await loadStores();
  }

  /// removing a store and all its associated data (cascade delete).
  Future<void> removeStore(int id) async {
    await _db.deleteStore(id);
    await loadStores();
  }

  // ── category management ──

  /// adding a new category to the currently selected store.
  Future<void> addCategory(String name, String? description) async {
    if (_selectedStore == null) return;
    final cat = models.Category(storeId: _selectedStore!.id!, name: name, description: description);
    await _db.insertCategory(cat);
    await loadCategories();
  }

  /// updating an existing category's details.
  Future<void> editCategory(models.Category category) async {
    await _db.updateCategory(category);
    await loadCategories();
  }

  /// removing a category and refreshing both categories and products.
  Future<void> removeCategory(int id) async {
    await _db.deleteCategory(id);
    await loadCategories();
    await loadProducts(); // reloading products since some may have been cascade-deleted
  }

  // ── product management ──

  /// adding a new product and refreshing both products and brands lists.
  Future<void> addProduct(Product product) async {
    await _db.insertProduct(product);
    await loadProducts();
    await loadBrands(); // refreshing brands in case a new brand was introduced
  }

  /// updating an existing product and triggering a restock notification
  /// if the product's quantity is at or below its restock threshold.
  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    // checking if a restock notification should be triggered
    if (product.needsRestock && _selectedStore != null) {
      await _notifications.showRestockAlert(
        _selectedStore!.name,
        product.name,
        product.quantity,
      );
    }
    await loadProducts();
  }

  /// convenience method for updating just the quantity of a product.
  Future<void> updateProductQuantity(Product product, int newQuantity) async {
    final updated = product.copyWith(quantity: newQuantity);
    await updateProduct(updated);
  }

  /// removing a product and refreshing both products and brands lists.
  Future<void> removeProduct(int id) async {
    await _db.deleteProduct(id);
    await loadProducts();
    await loadBrands(); // refreshing brands in case the last product of a brand was removed
  }

  // ── barcode scanning ──

  /// looking up a product by its scanned barcode within the selected store.
  /// returning null if no matching product is found.
  Future<Product?> lookupBarcode(String barcode) async {
    if (_selectedStore == null) return null;
    return await _db.getProductByBarcode(barcode, _selectedStore!.id!);
  }

  /// toggling a product's verification status and sending a notification.
  Future<void> verifyProduct(Product product, bool verified) async {
    final updated = product.copyWith(verified: verified);
    await _db.updateProduct(updated);
    await _notifications.showVerificationResult(product.name, verified);
    await loadProducts();
  }

  // ── statistics ──

  /// getting the total product count for the selected store.
  Future<int> getProductCount() async {
    if (_selectedStore == null) return 0;
    return await _db.getProductCount(_selectedStore!.id!);
  }

  /// getting the count of low-stock products for the selected store.
  Future<int> getLowStockCount() async {
    if (_selectedStore == null) return 0;
    return await _db.getLowStockCount(_selectedStore!.id!);
  }

  /// getting all low-stock products for the selected store.
  Future<List<Product>> getLowStockProducts() async {
    if (_selectedStore == null) return [];
    return await _db.getLowStockProducts(_selectedStore!.id!);
  }

  /// sending restock notifications for all low-stock products in the store.
  Future<void> checkAndNotifyLowStock() async {
    if (_selectedStore == null) return;
    final lowStock = await _db.getLowStockProducts(_selectedStore!.id!);
    // iterating through each low-stock product and dispatching a notification
    for (final product in lowStock) {
      await _notifications.showRestockAlert(
        _selectedStore!.name,
        product.name,
        product.quantity,
      );
    }
  }
}
