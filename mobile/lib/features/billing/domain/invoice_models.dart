import 'billing_calculator.dart';

enum InvoiceStatus { draft, issued, paid, overdue, cancelled }

String invoiceStatusToDb(InvoiceStatus status) => status.name;

InvoiceStatus invoiceStatusFromDb(String value) {
  return InvoiceStatus.values.firstWhere(
    (s) => s.name == value.toLowerCase(),
    orElse: () => InvoiceStatus.draft,
  );
}

class InvoiceDraftLineInput {
  const InvoiceDraftLineInput({
    required this.productId,
    required this.productNameSnapshot,
    this.unitSnapshot,
    required this.quantity,
    required this.unitPrice,
  });

  final String? productId;
  final String productNameSnapshot;
  final String? unitSnapshot;
  final double quantity;
  final double unitPrice;

  BillingLineInput toBillingLine() =>
      BillingLineInput(quantity: quantity, unitPrice: unitPrice);
}

class InvoiceDraftInput {
  const InvoiceDraftInput({
    required this.businessId,
    this.customerId,
    required this.items,
    this.notes,
    this.dueDateAd,
    this.invoiceDiscountAmount = 0,
  });

  final String businessId;
  final String? customerId;
  final List<InvoiceDraftLineInput> items;
  final String? notes;
  final DateTime? dueDateAd;
  final double invoiceDiscountAmount;
}

class InvoicePaymentInput {
  const InvoicePaymentInput({
    required this.amount,
    required this.method,
    this.note,
    this.paidAt,
  });

  final double amount;
  final String method;
  final String? note;
  final DateTime? paidAt;
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.businessId,
    required this.status,
    required this.invoiceNumber,
    required this.currencyCode,
    required this.languageSnapshot,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.paidAmount,
    required this.balanceDue,
    this.customerId,
    this.issueDate,
    this.dueDate,
    this.issueDateAd,
    this.dueDateAd,
    this.notes,
    this.pdfStatus,
    this.pdfPath,
    this.termsSnapshot,
    this.footerSnapshot,
    this.businessNameSnapshot,
    this.businessAddressSnapshot,
    this.businessPhoneSnapshot,
    this.businessEmailSnapshot,
    this.businessPanVatSnapshot,
  });

  final String id;
  final String businessId;
  final InvoiceStatus status;
  final String? invoiceNumber;
  final String currencyCode;
  final String languageSnapshot;
  final String? customerId;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? issueDateAd;
  final DateTime? dueDateAd;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final double paidAmount;
  final double balanceDue;
  final String? notes;
  final String? pdfStatus;
  final String? pdfPath;
  final String? termsSnapshot;
  final String? footerSnapshot;
  final String? businessNameSnapshot;
  final String? businessAddressSnapshot;
  final String? businessPhoneSnapshot;
  final String? businessEmailSnapshot;
  final String? businessPanVatSnapshot;

  factory InvoiceRecord.fromMap(Map<String, dynamic> row) {
    DateTime? parseDate(String key) {
      final raw = row[key]?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return InvoiceRecord(
      id: row['id']?.toString() ?? '',
      businessId: row['business_id']?.toString() ?? '',
      status: invoiceStatusFromDb((row['status'] ?? 'draft').toString()),
      invoiceNumber: row['invoice_number']?.toString(),
      currencyCode: row['currency_code']?.toString() ?? 'NPR',
      languageSnapshot: row['language_snapshot']?.toString() ?? 'en',
      customerId: row['customer_id']?.toString(),
      issueDate: parseDate('issue_date'),
      dueDate: parseDate('due_date'),
      issueDateAd: parseDate('issue_date_ad'),
      dueDateAd: parseDate('due_date_ad'),
      subtotal: (row['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (row['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (row['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (row['total'] as num?)?.toDouble() ?? 0,
      paidAmount: (row['paid_amount'] as num?)?.toDouble() ?? 0,
      balanceDue: (row['balance_due'] as num?)?.toDouble() ?? 0,
      notes: row['notes']?.toString(),
      pdfStatus: row['pdf_status']?.toString(),
      pdfPath: row['pdf_path']?.toString(),
      termsSnapshot: row['terms_snapshot']?.toString(),
      footerSnapshot: row['footer_snapshot']?.toString(),
      businessNameSnapshot: row['business_name_snapshot']?.toString(),
      businessAddressSnapshot: row['business_address_snapshot']?.toString(),
      businessPhoneSnapshot: row['business_phone_snapshot']?.toString(),
      businessEmailSnapshot: row['business_email_snapshot']?.toString(),
      businessPanVatSnapshot: row['business_pan_vat_snapshot']?.toString(),
    );
  }
}

class InvoiceItemRecord {
  const InvoiceItemRecord({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.productNameSnapshot,
    this.unitSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.taxRateSnapshot,
    required this.lineSubtotal,
    required this.lineTax,
    required this.lineTotal,
  });

  final String id;
  final String invoiceId;
  final String? productId;
  final String productNameSnapshot;
  final String? unitSnapshot;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double taxRateSnapshot;
  final double lineSubtotal;
  final double lineTax;
  final double lineTotal;

  factory InvoiceItemRecord.fromMap(Map<String, dynamic> row) =>
      InvoiceItemRecord(
        id: row['id']?.toString() ?? '',
        invoiceId: row['invoice_id']?.toString() ?? '',
        productId: row['product_id']?.toString(),
        productNameSnapshot: row['product_name_snapshot']?.toString() ?? '',
        unitSnapshot: row['unit_snapshot']?.toString(),
        quantity: (row['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (row['unit_price'] as num?)?.toDouble() ?? 0,
        discount: (row['discount'] as num?)?.toDouble() ?? 0,
        taxRateSnapshot: (row['tax_rate_snapshot'] as num?)?.toDouble() ?? 0,
        lineSubtotal: (row['line_subtotal'] as num?)?.toDouble() ?? 0,
        lineTax: (row['line_tax'] as num?)?.toDouble() ?? 0,
        lineTotal: (row['line_total'] as num?)?.toDouble() ?? 0,
      );
}

class InvoicePaymentRecord {
  const InvoicePaymentRecord({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.note,
  });

  final String id;
  final String invoiceId;
  final double amount;
  final String method;
  final DateTime paidAt;
  final String? note;

  factory InvoicePaymentRecord.fromMap(Map<String, dynamic> row) {
    final paidAt = DateTime.tryParse(row['paid_at']?.toString() ?? '');
    return InvoicePaymentRecord(
      id: row['id']?.toString() ?? '',
      invoiceId: row['invoice_id']?.toString() ?? '',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      method: row['method']?.toString() ?? 'CASH',
      paidAt: paidAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      note: row['note']?.toString(),
    );
  }
}
