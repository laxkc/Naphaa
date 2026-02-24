enum SaleType { cash, credit, mixed }

enum PaymentMethod { cash, qr, bank, credit, mixed }

String saleTypeToApi(SaleType value) {
  switch (value) {
    case SaleType.cash:
      return 'CASH';
    case SaleType.credit:
      return 'CREDIT';
    case SaleType.mixed:
      return 'MIXED';
  }
}

String paymentMethodToApi(PaymentMethod value) {
  switch (value) {
    case PaymentMethod.cash:
      return 'CASH';
    case PaymentMethod.qr:
      return 'QR';
    case PaymentMethod.bank:
      return 'BANK';
    case PaymentMethod.credit:
      return 'CREDIT';
    case PaymentMethod.mixed:
      return 'MIXED';
  }
}

class SaleItemInput {
  SaleItemInput({
    required this.productId,
    required this.qty,
    required this.unitPrice,
  });

  final String productId;
  final double qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;
}

class SalePaymentInput {
  SalePaymentInput({required this.method, required this.amount});

  final PaymentMethod method;
  final double amount;
}

class SaleInput {
  SaleInput({
    required this.saleType,
    this.paymentMethod,
    this.customerId,
    required this.items,
    this.payments = const [],
  });

  final String saleType;
  final PaymentMethod? paymentMethod;
  final String? customerId;
  final List<SaleItemInput> items;
  final List<SalePaymentInput> payments;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.lineTotal);

  double get creditAmount {
    if (payments.isEmpty) {
      return saleType == 'CREDIT' ? totalAmount : 0;
    }
    return payments
        .where((p) => p.method == PaymentMethod.credit)
        .fold(0.0, (sum, p) => sum + p.amount);
  }
}
