/// representing a retail store in the carta inventory system.
///
/// storing the store's identity, location, and contact info.
/// mapping to the `stores` table in sqlite.
class Store {
  final int? id; // auto-generated primary key from sqlite
  final String name; // display name of the store
  final String address; // physical location of the store
  final String? phone; // optional contact number
  final DateTime createdAt; // timestamp tracking when the store was added

  Store({
    this.id,
    required this.name,
    required this.address,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(); // defaulting to now if not provided

  /// converting the store instance to a map for sqlite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// constructing a store from a sqlite row map.
  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// creating a modified copy of this store, preserving unchanged fields.
  Store copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
