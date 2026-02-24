enum SaleStatus { completed, refunded, partial }

class Sale {
  Sale({
    required this.id,
    required this.totalAmount,
    required this.saleType,
    required this.createdAt,
    this.customerId,
    this.customerName,
    this.status = SaleStatus.completed,
    this.items = const [],
    this.payments = const [],
    this.note,
  });

  final String id;
  final double totalAmount;
  final String saleType; // CASH, CREDIT, MIXED
  final DateTime createdAt;
  final String? customerId;
  final String? customerName;
  final SaleStatus status;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final String? note;

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      saleType: map['sale_type'] as String? ?? 'CASH',
      createdAt: DateTime.parse(map['created_at'] as String),
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      status: _parseStatus(map['status'] as String?),
      note: map['note'] as String?,
    );
  }

  static SaleStatus _parseStatus(String? s) {
    switch (s) {
      case 'refunded':
        return SaleStatus.refunded;
      case 'partial':
        return SaleStatus.partial;
      default:
        return SaleStatus.completed;
    }
  }
}

class SaleItem {
  SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
  });

  final String id;
  final String productId;
  final String productName;
  final double qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String? ?? '',
      qty: (map['qty'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
    );
  }
}

class SalePayment {
  SalePayment({
    required this.id,
    required this.method,
    required this.amount,
  });

  final String id;
  final String method; // CASH, QR, BANK, CREDIT
  final double amount;

  factory SalePayment.fromMap(Map<String, dynamic> map) {
    return SalePayment(
      id: map['id'] as String,
      method: map['method'] as String? ?? 'CASH',
      amount: (map['amount'] as num).toDouble(),
    );
  }
}
