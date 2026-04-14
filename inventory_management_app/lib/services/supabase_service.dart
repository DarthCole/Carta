import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../models/category.dart' as models;
import '../models/product.dart';
import '../models/purchase_order.dart';
import 'database_service.dart';

/// sync service for orchestrating cloud backups to supabase.
/// this ensures offline-first reliability while keeping a remote backup.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;
  final _db = DatabaseService();

  Future<void> syncAll() async {
    try {
      debugPrint('Supabase: starting full manual sync...');
      
      final stores = await _db.getStores();
      for (final s in stores) await upsertStore(s);

      for (final s in stores) {
        final categories = await _db.getCategories(s.id!);
        for (final c in categories) await upsertCategory(c);

        final products = await _db.getProducts(s.id!);
        for (final p in products) await upsertProduct(p);

        final orders = await _db.getPurchaseOrders(s.id!);
        for (final o in orders) await upsertPurchaseOrder(o);
      }
      debugPrint('Supabase: manual sync completed successfully.');
    } catch (e) {
      debugPrint('Supabase: manual sync failed - $e');
      rethrow;
    }
  }

  Future<void> syncDownAll() async {
    try {
      debugPrint('Supabase: starting full manual pull sync...');
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final stores = await _supabase.from('stores').select().eq('user_id', user.id);
      final categories = await _supabase.from('categories').select().eq('user_id', user.id);
      final products = await _supabase.from('products').select().eq('user_id', user.id);
      final orders = await _supabase.from('purchase_orders').select().eq('user_id', user.id);

      await _db.populateFromCloud(
        stores: stores,
        categories: categories,
        products: products,
        purchaseOrders: orders,
      );

      debugPrint('Supabase: pull sync completed successfully.');
    } catch (e) {
      debugPrint('Supabase: pull sync failed - $e');
      rethrow;
    }
  }

  Map<String, dynamic> _injectUserId(Map<String, dynamic> data) {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      data['user_id'] = user.id;
    }
    return data;
  }

  // ── stores ──
  Future<void> upsertStore(Store store) async {
    try {
      await _supabase.from('stores').upsert(_injectUserId(store.toMap()));
      debugPrint('Supabase: synced store ${store.id}');
    } catch (e) {
      debugPrint('Supabase sync error (store): $e');
    }
  }

  Future<void> deleteStore(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('stores').delete().eq('id', id).eq('user_id', user.id);
      debugPrint('Supabase: deleted store $id');
    } catch (e) {
      debugPrint('Supabase sync error (delete store): $e');
    }
  }

  // ── categories ──
  Future<void> upsertCategory(models.Category category) async {
    try {
      await _supabase.from('categories').upsert(_injectUserId(category.toMap()));
      debugPrint('Supabase: synced category ${category.id}');
    } catch (e) {
      debugPrint('Supabase sync error (category): $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('categories').delete().eq('id', id).eq('user_id', user.id);
      debugPrint('Supabase: deleted category $id');
    } catch (e) {
      debugPrint('Supabase sync error (delete category): $e');
    }
  }

  // ── products ──
  Future<void> upsertProduct(Product product) async {
    try {
      await _supabase.from('products').upsert(_injectUserId(product.toMap()));
      debugPrint('Supabase: synced product ${product.id}');
    } catch (e) {
      debugPrint('Supabase sync error (product): $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('products').delete().eq('id', id).eq('user_id', user.id);
      debugPrint('Supabase: deleted product $id');
    } catch (e) {
      debugPrint('Supabase sync error (delete product): $e');
    }
  }

  // ── purchase orders ──
  Future<void> upsertPurchaseOrder(PurchaseOrder order) async {
    try {
      await _supabase.from('purchase_orders').upsert(_injectUserId(order.toMap()));
      debugPrint('Supabase: synced purchase order ${order.id}');
    } catch (e) {
      debugPrint('Supabase sync error (purchase_order): $e');
    }
  }

  Future<void> deletePurchaseOrder(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('purchase_orders').delete().eq('id', id).eq('user_id', user.id);
      debugPrint('Supabase: deleted purchase order $id');
    } catch (e) {
      debugPrint('Supabase sync error (delete purchase_order): $e');
    }
  }
}
