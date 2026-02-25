import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/features/billing/domain/billing_calculator.dart';

void main() {
  group('BillingCalculator', () {
    test('returns zero totals for empty lines', () {
      final result = BillingCalculator.calculate(
        lines: const [],
        vatEnabled: true,
        vatRatePercent: 13,
        taxMode: BillingTaxMode.exclusive,
      );

      expect(result.baseTotal, 0);
      expect(result.discountAmount, 0);
      expect(result.subtotal, 0);
      expect(result.taxAmount, 0);
      expect(result.total, 0);
      expect(result.lines, isEmpty);
    });

    test('calculates VAT exclusive totals', () {
      final result = BillingCalculator.calculate(
        lines: const [
          BillingLineInput(quantity: 2, unitPrice: 100), // 200
          BillingLineInput(quantity: 1, unitPrice: 50), // 50
        ],
        vatEnabled: true,
        vatRatePercent: 13,
        taxMode: BillingTaxMode.exclusive,
      );

      expect(result.baseTotal, 250);
      expect(result.subtotal, 250);
      expect(result.taxAmount, 32.5);
      expect(result.total, 282.5);
    });

    test('calculates VAT inclusive totals', () {
      final result = BillingCalculator.calculate(
        lines: const [
          BillingLineInput(quantity: 1, unitPrice: 113),
        ],
        vatEnabled: true,
        vatRatePercent: 13,
        taxMode: BillingTaxMode.inclusive,
      );

      expect(result.total, 113);
      expect(result.taxAmount, 13);
      expect(result.subtotal, 100);
    });

    test('disables VAT fully when vatEnabled is false', () {
      final result = BillingCalculator.calculate(
        lines: const [
          BillingLineInput(quantity: 3, unitPrice: 99.99),
        ],
        vatEnabled: false,
        vatRatePercent: 13,
        taxMode: BillingTaxMode.exclusive,
      );

      expect(result.taxAmount, 0);
      expect(result.subtotal, result.total);
    });

    test('applies invoice-level discount proportionally and clamps over-discount', () {
      final result = BillingCalculator.calculate(
        lines: const [
          BillingLineInput(quantity: 1, unitPrice: 100),
          BillingLineInput(quantity: 1, unitPrice: 200),
        ],
        vatEnabled: true,
        vatRatePercent: 13,
        taxMode: BillingTaxMode.exclusive,
        invoiceDiscountAmount: 999, // should clamp to baseTotal=300
      );

      expect(result.baseTotal, 300);
      expect(result.discountAmount, 300);
      expect(result.subtotal, 0);
      expect(result.taxAmount, 0);
      expect(result.total, 0);
    });

    test('rounds line values to 2 decimals consistently', () {
      final result = BillingCalculator.calculate(
        lines: const [
          BillingLineInput(quantity: 3, unitPrice: 33.3333),
        ],
        vatEnabled: true,
        vatRatePercent: 13,
        taxMode: BillingTaxMode.exclusive,
      );

      expect(result.baseTotal, 100.0);
      expect(result.taxAmount, 13.0);
      expect(result.total, 113.0);
    });
  });
}

