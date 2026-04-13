/// representing a purchase order for incoming inventory.
///
/// tracking supplier orders, delivery status, and quantities.
/// implements the Purchase Orders screen from the Team Progress Update spec.
class PurchaseOrder {
  final int? id;
  final int storeId;
  final int productId;
  final String productName;
  final String supplier;
  final int quantity;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final bool delivered;
  final String? notes;

  PurchaseOrder({
    this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.supplier,
    required this.quantity,
    DateTime? orderDate,
    this.deliveryDate,
    this.delivered = false,
    this.notes,
  }) : orderDate = orderDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'product_id': productId,
      'product_name': productName,
      'supplier': supplier,
      'quantity': quantity,
      'order_date': orderDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'delivered': delivered ? 1 : 0,
      'notes': notes,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'] as int?,
      storeId: map['store_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      supplier: map['supplier'] as String,
      quantity: map['quantity'] as int,
      orderDate: DateTime.parse(map['order_date'] as String),
      deliveryDate: map['delivery_date'] != null
          ? DateTime.parse(map['delivery_date'] as String)
          : null,
      delivered: (map['delivered'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
    );
  }

  PurchaseOrder copyWith({
    int? id,
    int? storeId,
    int? productId,
    String? productName,
    String? supplier,
    int? quantity,
    DateTime? orderDate,
    DateTime? deliveryDate,
    bool? delivered,
    String? notes,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      supplier: supplier ?? this.supplier,
      quantity: quantity ?? this.quantity,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      delivered: delivered ?? this.delivered,
      notes: notes ?? this.notes,
    );
  }
}
