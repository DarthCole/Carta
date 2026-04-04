class Store {
  final int? id;
  final String name;
  final String address;
  final String? phone;
  final DateTime createdAt;

  Store({
    this.id,
    required this.name,
    required this.address,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

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
