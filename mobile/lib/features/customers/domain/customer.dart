class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.balance,
    this.phone,
    this.address,
    this.notes,
    this.createdAt,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final double balance;
  final DateTime? createdAt;
  final bool isDeleted;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      balance: (map['balance'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    String? notes,
    double? balance,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'balance': balance,
      'created_at': createdAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}
