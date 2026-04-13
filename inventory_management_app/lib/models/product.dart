/// representing an individual product in a store's inventory.
///
/// now includes supplier info, delivery tracking, manual low-stock flagging,
/// and reorder interval for time-based "Reorder Soon" logic.
class Product {
  final int? id;
  final int storeId;
  final int categoryId;
  final String name;
  final String brand;
  final String? barcode;
  final int quantity;
  final int restockThreshold;
  final double price;
  final bool verified;
  final DateTime lastUpdated;
  // ── new fields from Team Progress Update spec ──
  final String? supplier;
  final DateTime? lastDeliveryDate;
  final bool lowStockFlagged; // manual low-stock flag by store manager
  final int reorderIntervalDays; // typical days between deliveries

  Product({
    this.id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    required this.brand,
    this.barcode,
    required this.quantity,
    this.restockThreshold = 10,
    required this.price,
    this.verified = false,
    DateTime? lastUpdated,
    this.supplier,
    this.lastDeliveryDate,
    this.lowStockFlagged = false,
    this.reorderIntervalDays = 7,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'category_id': categoryId,
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'quantity': quantity,
      'restock_threshold': restockThreshold,
      'price': price,
      'verified': verified ? 1 : 0,
      'last_updated': lastUpdated.toIso8601String(),
      'supplier': supplier,
      'last_delivery_date': lastDeliveryDate?.toIso8601String(),
      'low_stock_flagged': lowStockFlagged ? 1 : 0,
      'reorder_interval_days': reorderIntervalDays,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      storeId: map['store_id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      brand: map['brand'] as String,
      barcode: map['barcode'] as String?,
      quantity: map['quantity'] as int,
      restockThreshold: map['restock_threshold'] as int? ?? 10,
      price: (map['price'] as num).toDouble(),
      verified: (map['verified'] as int? ?? 0) == 1,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      supplier: map['supplier'] as String?,
      lastDeliveryDate: map['last_delivery_date'] != null
          ? DateTime.parse(map['last_delivery_date'] as String)
          : null,
      lowStockFlagged: (map['low_stock_flagged'] as int? ?? 0) == 1,
      reorderIntervalDays: map['reorder_interval_days'] as int? ?? 7,
    );
  }

  Product copyWith({
    int? id,
    int? storeId,
    int? categoryId,
    String? name,
    String? brand,
    String? barcode,
    int? quantity,
    int? restockThreshold,
    double? price,
    bool? verified,
    DateTime? lastUpdated,
    String? supplier,
    DateTime? lastDeliveryDate,
    bool? lowStockFlagged,
    int? reorderIntervalDays,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      restockThreshold: restockThreshold ?? this.restockThreshold,
      price: price ?? this.price,
      verified: verified ?? this.verified,
      lastUpdated: lastUpdated ?? DateTime.now(),
      supplier: supplier ?? this.supplier,
      lastDeliveryDate: lastDeliveryDate ?? this.lastDeliveryDate,
      lowStockFlagged: lowStockFlagged ?? this.lowStockFlagged,
      reorderIntervalDays: reorderIntervalDays ?? this.reorderIntervalDays,
    );
  }

  /// automatic threshold-based restock check
  bool get needsRestock => quantity <= restockThreshold;

  /// time-based "Reorder Soon" logic: if days since last delivery
  /// exceeds the typical reorder interval, suggest reorder
  bool get reorderSoon {
    if (lastDeliveryDate == null) return false;
    final daysSinceDelivery = DateTime.now().difference(lastDeliveryDate!).inDays;
    return daysSinceDelivery >= reorderIntervalDays;
  }

  /// overall status for display badges
  String get stockStatus {
    if (lowStockFlagged) return 'Low Stock';
    if (reorderSoon) return 'Reorder Soon';
    if (needsRestock) return 'Low Stock';
    return 'OK';
  }
}
