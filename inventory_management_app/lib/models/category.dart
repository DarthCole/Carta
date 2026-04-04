/// representing a product category within a specific store.
///
/// grouping products into logical categories (e.g. beverages, snacks).
/// mapping to the `categories` table in sqlite.
class Category {
  final int? id; // auto-generated primary key from sqlite
  final int storeId; // foreign key linking to the parent store
  final String name; // display name of the category
  final String? description; // optional description of what this category contains

  Category({
    this.id,
    required this.storeId,
    required this.name,
    this.description,
  });

  /// converting the category instance to a map for sqlite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'description': description,
    };
  }

  /// constructing a category from a sqlite row map.
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      storeId: map['store_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }

  /// creating a modified copy of this category, preserving unchanged fields.
  Category copyWith({int? id, int? storeId, String? name, String? description}) {
    return Category(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
