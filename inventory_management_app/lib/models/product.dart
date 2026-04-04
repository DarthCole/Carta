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
    );
  }

  bool get needsRestock => quantity <= restockThreshold;
}
