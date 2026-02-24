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
}
