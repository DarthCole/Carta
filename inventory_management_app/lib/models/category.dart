class Category {
  final int? id;
  final int storeId;
  final String name;
  final String? description;

  Category({
    this.id,
    required this.storeId,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'description': description,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      storeId: map['store_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }

  Category copyWith({int? id, int? storeId, String? name, String? description}) {
    return Category(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
