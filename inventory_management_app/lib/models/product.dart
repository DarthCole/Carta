/// representing an individual product in a store's inventory.
///
/// tracking stock levels, pricing, barcode data, and verification status.
/// mapping to the `products` table in sqlite.
class Product {
  final int? id; // auto-generated primary key from sqlite
  final int storeId; // foreign key linking to the parent store
  final int categoryId; // foreign key linking to the product's category
  final String name; // display name of the product
  final String brand; // manufacturer or brand name
  final String? barcode; // optional barcode or qr code value for scanning
  final int quantity; // current stock count on hand
  final int restockThreshold; // minimum stock level before triggering a low-stock alert
  final double price; // unit price in ghc
  final bool verified; // indicating whether the product has been verified via barcode scan
  final DateTime lastUpdated; // timestamp of the most recent modification

  Product({
    this.id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    required this.brand,
    this.barcode,
    required this.quantity,
    this.restockThreshold = 10, // defaulting to 10 units as the restock trigger
    required this.price,
    this.verified = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now(); // defaulting to now if not provided

  /// converting the product instance to a map for sqlite insertion.
  /// storing the verified flag as an integer (0/1) for sqlite compatibility.
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
      'verified': verified ? 1 : 0, // converting bool to int for sqlite
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// constructing a product from a sqlite row map.
  /// parsing the verified integer back to a boolean.
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
      verified: (map['verified'] as int? ?? 0) == 1, // converting int back to bool
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }

  /// creating a modified copy of this product, preserving unchanged fields.
  /// resetting lastUpdated to now on every copy to track modifications.
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

  /// checking whether the current stock is at or below the restock threshold.
  /// returning true when a restock notification should be considered.
  bool get needsRestock => quantity <= restockThreshold;
}
