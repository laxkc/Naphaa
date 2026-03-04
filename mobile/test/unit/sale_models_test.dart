import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/features/sales/domain/sale_models.dart';

void main() {
  test('sale total calculation is correct', () {
    final input = SaleInput(
      saleType: 'CASH',
      items: [
        SaleItemInput(productId: 'p1', qty: 2, unitPrice: 50),
        SaleItemInput(productId: 'p2', qty: 1, unitPrice: 30),
      ],
    );

    expect(input.totalAmount, 130);
  });

  test('payment method mapping supports wallet', () {
    expect(paymentMethodToApi(PaymentMethod.wallet), 'WALLET');
  });

  test('credit amount is derived from split payments', () {
    final input = SaleInput(
      saleType: 'MIXED',
      items: [SaleItemInput(productId: 'p1', qty: 2, unitPrice: 100)],
      payments: [
        SalePaymentInput(method: PaymentMethod.cash, amount: 120),
        SalePaymentInput(method: PaymentMethod.credit, amount: 80),
      ],
    );
    expect(input.totalAmount, 200);
    expect(input.creditAmount, 80);
  });
}
