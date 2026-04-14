import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/store.dart';
import '../models/category.dart' as models;
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

/// centralised state management for the carta inventory app.
/// now includes purchase order management, dashboard data, and haptic feedback.
class InventoryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  final SupabaseService _supabaseService = SupabaseService();

  // ── state fields ──
  List<Store> _stores = [];
  List<models.Category> _categories = [];
  List<Product> _products = [];
  List<String> _brands = [];
  List<PurchaseOrder> _purchaseOrders = [];

  Store? _selectedStore;
  models.Category? _selectedCategory;
  String? _selectedBrand;
  String _searchQuery = '';

  // ── getters ──
  List<Store> get stores => _stores;
  List<models.Category> get categories => _categories;
  List<Product> get products => _products;
  List<String> get brands => _brands;
  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  Store? get selectedStore => _selectedStore;
  models.Category? get selectedCategory => _selectedCategory;
  String? get selectedBrand => _selectedBrand;
  String get searchQuery => _searchQuery;

  // ── haptic feedback helper ──
  void _hapticLight() => HapticFeedback.lightImpact();
  void _hapticMedium() => HapticFeedback.mediumImpact();
  void _hapticHeavy() => HapticFeedback.heavyImpact();

  // ── store operations ──

  Future<void> loadStores() async {
    _stores = await _db.getStores();
    notifyListeners();
  }

  void selectStore(Store store) {
    _selectedStore = store;
    _selectedCategory = null;
    _selectedBrand = null;
    _searchQuery = '';
    _hapticLight();
    notifyListeners();
  }

  Future<void> addStore(String name, String address, String? phone) async {
    final store = Store(name: name, address: address, phone: phone);
    final inserted = await _db.insertStore(store);
    await _supabaseService.upsertStore(inserted);
    _hapticMedium();
    await loadStores();
  }

  Future<void> editStore(Store store) async {
    await _db.updateStore(store);
    await _supabaseService.upsertStore(store);
    await loadStores();
  }

  Future<void> removeStore(int id) async {
    await _db.deleteStore(id);
    await _supabaseService.deleteStore(id);
    _hapticHeavy();
    await loadStores();
  }

  // ── category operations ──

  Future<void> loadCategories() async {
    if (_selectedStore == null) return;
    _categories = await _db.getCategories(_selectedStore!.id!);
    notifyListeners();
  }

  Future<void> addCategory(String name, String? description) async {
    if (_selectedStore == null) return;
    final cat = models.Category(storeId: _selectedStore!.id!, name: name, description: description);
    final inserted = await _db.insertCategory(cat);
    await _supabaseService.upsertCategory(inserted);
    _hapticMedium();
    await loadCategories();
  }

  Future<void> editCategory(models.Category category) async {
    await _db.updateCategory(category);
    await _supabaseService.upsertCategory(category);
    await loadCategories();
  }

  Future<void> removeCategory(int id) async {
    await _db.deleteCategory(id);
    await _supabaseService.deleteCategory(id);
    _hapticHeavy();
    await loadCategories();
    await loadProducts();
  }

  // ── product operations ──

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

  void setSelectedCategory(models.Category? category) {
    _selectedCategory = category;
    _hapticLight();
    loadProducts();
  }

  void setSelectedBrand(String? brand) {
    _selectedBrand = brand;
    _hapticLight();
    loadProducts();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedBrand = null;
    _searchQuery = '';
    loadProducts();
  }

  Future<void> addProduct(Product product) async {
    final inserted = await _db.insertProduct(product);
    await _supabaseService.upsertProduct(inserted);
    _hapticMedium();
    await loadProducts();
    await loadBrands();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    await _supabaseService.upsertProduct(product);
    await loadProducts();
  }

  Future<void> updateProductQuantity(Product product, int newQuantity) async {
    final updated = product.copyWith(quantity: newQuantity);
    await _db.updateProduct(updated);
    await _supabaseService.upsertProduct(updated);
    _hapticLight();

    if (newQuantity <= product.restockThreshold && _selectedStore != null) {
      await _notifications.showRestockAlert(
        _selectedStore!.name, product.name, newQuantity,
      );
    }
    await loadProducts();
  }

  Future<void> removeProduct(int id) async {
    await _db.deleteProduct(id);
    await _supabaseService.deleteProduct(id);
    _hapticHeavy();
    await loadProducts();
    await loadBrands();
  }

  Future<void> verifyProduct(Product product, bool verified) async {
    final updated = product.copyWith(verified: verified);
    await _db.updateProduct(updated);
    await _supabaseService.upsertProduct(updated);
    await _notifications.showVerificationResult(product.name, verified);
    _hapticMedium();
    await loadProducts();
  }

  // ── manual low stock flag operations ──

  Future<void> flagLowStock(Product product) async {
    final updated = product.copyWith(lowStockFlagged: true);
    await _db.updateProduct(updated);
    await _supabaseService.upsertProduct(updated);
    _hapticMedium();
    await loadProducts();
  }

  Future<void> unflagLowStock(Product product) async {
    final updated = product.copyWith(lowStockFlagged: false);
    await _db.updateProduct(updated);
    await _supabaseService.upsertProduct(updated);
    _hapticLight();
    await loadProducts();
  }

  // ── purchase order operations ──

  Future<void> loadPurchaseOrders({bool? delivered}) async {
    if (_selectedStore == null) return;
    _purchaseOrders = await _db.getPurchaseOrders(_selectedStore!.id!, delivered: delivered);
    notifyListeners();
  }

  Future<void> addPurchaseOrder(PurchaseOrder order) async {
    final inserted = await _db.insertPurchaseOrder(order);
    await _supabaseService.upsertPurchaseOrder(inserted);
    _hapticMedium();
    await loadPurchaseOrders();
  }

  Future<void> markOrderDelivered(PurchaseOrder order) async {
    await _db.markOrderDelivered(order);
    
    // Also push the updated order and product to Supabase so it stays in sync
    final updatedOrder = order.copyWith(delivered: true, deliveryDate: DateTime.now());
    await _supabaseService.upsertPurchaseOrder(updatedOrder);
    
    // We should ideally fetch the updated product from local db instead of blind updating
    final products = await _db.getProducts(_selectedStore!.id!);
    final updatedProduct = products.firstWhere((p) => p.id == order.productId);
    await _supabaseService.upsertProduct(updatedProduct);

    await _notifications.showOrderDelivered(order.productName, order.quantity);
    _hapticHeavy();
    await loadPurchaseOrders();
    await loadProducts();
  }

  Future<void> deletePurchaseOrder(int id) async {
    await _db.deletePurchaseOrder(id);
    await _supabaseService.deletePurchaseOrder(id);
    _hapticHeavy();
    await loadPurchaseOrders();
  }

  // ── dashboard / statistics ──

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

  Future<List<Product>> getReorderSoonProducts() async {
    if (_selectedStore == null) return [];
    return await _db.getReorderSoonProducts(_selectedStore!.id!);
  }

  Future<List<Product>> getFlaggedLowStockProducts() async {
    if (_selectedStore == null) return [];
    return await _db.getFlaggedLowStockProducts(_selectedStore!.id!);
  }

  Future<List<PurchaseOrder>> getRecentDeliveries() async {
    if (_selectedStore == null) return [];
    return await _db.getRecentDeliveries(_selectedStore!.id!);
  }

  Future<int> getPendingOrderCount() async {
    if (_selectedStore == null) return 0;
    return await _db.getPendingOrderCount(_selectedStore!.id!);
  }

  Future<void> checkAndNotifyLowStock() async {
    if (_selectedStore == null) return;
    final lowStock = await _db.getLowStockProducts(_selectedStore!.id!);
    for (final product in lowStock) {
      await _notifications.showRestockAlert(
        _selectedStore!.name, product.name, product.quantity,
      );
    }
    _hapticHeavy();
  }

  Future<void> checkAndNotifyReorderSoon() async {
    if (_selectedStore == null) return;
    final reorderSoon = await _db.getReorderSoonProducts(_selectedStore!.id!);
    for (final product in reorderSoon) {
      final days = DateTime.now().difference(product.lastDeliveryDate!).inDays;
      await _notifications.showReorderSoonAlert(
        _selectedStore!.name, product.name, days,
      );
    }
  }
}
