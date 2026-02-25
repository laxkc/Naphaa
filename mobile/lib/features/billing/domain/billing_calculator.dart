enum BillingTaxMode { exclusive, inclusive }

class BillingLineInput {
  const BillingLineInput({
    required this.quantity,
    required this.unitPrice,
  });

  final double quantity;
  final double unitPrice;
}

class BillingLineResult {
  const BillingLineResult({
    required this.base,
    required this.discountAllocated,
    required this.lineSubtotal,
    required this.lineTax,
    required this.lineTotal,
  });

  final double base;
  final double discountAllocated;
  final double lineSubtotal;
  final double lineTax;
  final double lineTotal;
}

class BillingTotalsResult {
  const BillingTotalsResult({
    required this.lines,
    required this.baseTotal,
    required this.discountAmount,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
  });

  final List<BillingLineResult> lines;
  final double baseTotal;
  final double discountAmount;
  final double subtotal;
  final double taxAmount;
  final double total;
}

class BillingCalculator {
  const BillingCalculator._();

  static BillingTotalsResult calculate({
    required List<BillingLineInput> lines,
    required bool vatEnabled,
    required double vatRatePercent,
    required BillingTaxMode taxMode,
    double invoiceDiscountAmount = 0,
  }) {
    if (lines.isEmpty) {
      return const BillingTotalsResult(
        lines: [],
        baseTotal: 0,
        discountAmount: 0,
        subtotal: 0,
        taxAmount: 0,
        total: 0,
      );
    }

    final bases = lines.map((l) => _r2(l.quantity * l.unitPrice)).toList();
    final baseTotal = _r2(bases.fold<double>(0, (a, b) => a + b));
    final safeDiscount = _r2(
      invoiceDiscountAmount.clamp(0, baseTotal).toDouble(),
    );

    // Proportional invoice-level discount allocation; keep totals exact by applying
    // remainder to the last line.
    final discounts = List<double>.filled(lines.length, 0);
    if (safeDiscount > 0 && baseTotal > 0) {
      var allocated = 0.0;
      for (var i = 0; i < lines.length; i++) {
        if (i == lines.length - 1) {
          discounts[i] = _r2(safeDiscount - allocated);
        } else {
          discounts[i] = _r2((bases[i] / baseTotal) * safeDiscount);
          allocated = _r2(allocated + discounts[i]);
        }
      }
    }

    final taxRate = vatEnabled ? (vatRatePercent / 100.0) : 0.0;
    final results = <BillingLineResult>[];

    for (var i = 0; i < lines.length; i++) {
      final base = bases[i];
      final discount = discounts[i];
      final discounted = _r2(base - discount);

      if (!vatEnabled) {
        results.add(
          BillingLineResult(
            base: base,
            discountAllocated: discount,
            lineSubtotal: discounted,
            lineTax: 0,
            lineTotal: discounted,
          ),
        );
        continue;
      }

      if (taxMode == BillingTaxMode.exclusive) {
        final lineTax = _r2(discounted * taxRate);
        final lineSubtotal = discounted;
        final lineTotal = _r2(lineSubtotal + lineTax);
        results.add(
          BillingLineResult(
            base: base,
            discountAllocated: discount,
            lineSubtotal: lineSubtotal,
            lineTax: lineTax,
            lineTotal: lineTotal,
          ),
        );
      } else {
        final lineTotal = discounted;
        final lineTax = _r2(lineTotal * (taxRate / (1 + taxRate)));
        final lineSubtotal = _r2(lineTotal - lineTax);
        results.add(
          BillingLineResult(
            base: base,
            discountAllocated: discount,
            lineSubtotal: lineSubtotal,
            lineTax: lineTax,
            lineTotal: lineTotal,
          ),
        );
      }
    }

    final subtotal = _r2(results.fold<double>(0, (a, l) => a + l.lineSubtotal));
    final taxAmount = _r2(results.fold<double>(0, (a, l) => a + l.lineTax));
    final total = _r2(results.fold<double>(0, (a, l) => a + l.lineTotal));

    return BillingTotalsResult(
      lines: results,
      baseTotal: baseTotal,
      discountAmount: safeDiscount,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
    );
  }

  static double _r2(double v) => (v * 100).roundToDouble() / 100;
}

