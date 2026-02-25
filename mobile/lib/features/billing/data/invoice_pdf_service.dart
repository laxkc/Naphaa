import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/storage/preferences.dart';
import '../domain/invoice_models.dart';
import 'billing_repository.dart';

class InvoicePdfService {
  InvoicePdfService(this._repo, this._prefs);

  final BillingRepository _repo;
  final AppPreferences _prefs;

  Future<String> generateInvoicePdf(String invoiceId) async {
    final invoice = await _repo.getInvoiceById(invoiceId);
    if (invoice == null) throw StateError('Invoice not found');
    final items = await _repo.getInvoiceItems(invoiceId);
    final payments = await _repo.getInvoicePayments(invoiceId);
    if (items.isEmpty) throw StateError('Invoice has no items');

    try {
      final settings = await _prefs.getBillingSettings();
      final pdf = pw.Document();
      final nf = _currencyFormatter;
      final dateFmt = _dateFormatter;
      final lang =
          (invoice.languageSnapshot.trim().isNotEmpty
                  ? invoice.languageSnapshot
                  : (settings['language']?.toString() ?? 'en'))
              .toLowerCase();
      final currencyCode =
          invoice.currencyCode.trim().isNotEmpty ? invoice.currencyCode : 'NPR';
      final businessName = _firstNonEmpty(
        invoice.businessNameSnapshot,
        settings['business_name']?.toString(),
        fallback: 'Business',
      );
      final businessAddress = _firstNonEmpty(
        invoice.businessAddressSnapshot,
        settings['business_address']?.toString(),
      );
      final businessPhone = _firstNonEmpty(
        invoice.businessPhoneSnapshot,
        settings['business_phone']?.toString(),
      );
      final businessEmail = _firstNonEmpty(
        invoice.businessEmailSnapshot,
        settings['business_email']?.toString(),
      );
      final panVat = _firstNonEmpty(
        invoice.businessPanVatSnapshot,
        settings['pan_vat_number']?.toString(),
      );
      final terms = _firstNonEmpty(
        invoice.termsSnapshot,
        settings['invoice_terms_default']?.toString(),
      );
      final footer = _firstNonEmpty(
        invoice.footerSnapshot,
        settings['invoice_footer_default']?.toString(),
      );
      pw.ThemeData? docTheme;
      if (lang == 'ne') {
        try {
          final base = await PdfGoogleFonts.notoSansDevanagariRegular();
          final bold = await PdfGoogleFonts.notoSansDevanagariBold();
          docTheme = pw.ThemeData.withFont(base: base, bold: bold);
        } catch (_) {
          // Fallback to default PDF fonts if Google font fetch is unavailable.
          // Nepali text rendering may be limited; user can retry with internet.
        }
      }

      pdf.addPage(
        pw.MultiPage(
          theme: docTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build:
              (context) => [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            businessName,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (businessAddress.isNotEmpty)
                            pw.Text(businessAddress),
                          if (businessPhone.isNotEmpty)
                            pw.Text(
                              '${_t(lang, 'Phone', 'फोन')}: $businessPhone',
                            ),
                          if (businessEmail.isNotEmpty)
                            pw.Text(
                              '${_t(lang, 'Email', 'इमेल')}: $businessEmail',
                            ),
                          if (panVat.isNotEmpty)
                            pw.Text(
                              '${_t(lang, 'PAN/VAT', 'PAN/VAT')}: $panVat',
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          _t(lang, 'INVOICE', 'बिल'),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          invoice.invoiceNumber ?? _t(lang, 'DRAFT', 'ड्राफ्ट'),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${_t(lang, 'Date', 'मिति')}: ${dateFmt.format((invoice.issueDate ?? DateTime.now()).toLocal())}',
                        ),
                        if (invoice.dueDate != null)
                          pw.Text(
                            '${_t(lang, 'Due', 'बुझाउने मिति')}: ${dateFmt.format(invoice.dueDate!.toLocal())}',
                          ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  headers: [
                    _t(lang, 'Item', 'सामान'),
                    _t(lang, 'Qty', 'परिमाण'),
                    _t(lang, 'Rate', 'दर'),
                    _t(lang, 'Total', 'कुल'),
                  ],
                  data:
                      items
                          .map(
                            (i) => [
                              i.productNameSnapshot,
                              '${i.quantity} ${i.unitSnapshot ?? ''}'.trim(),
                              '$currencyCode ${nf.format(i.unitPrice)}',
                              '$currencyCode ${nf.format(i.lineTotal)}',
                            ],
                          )
                          .toList(),
                ),
                pw.SizedBox(height: 12),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.SizedBox(
                    width: 240,
                    child: pw.Column(
                      children: [
                        _pdfKv(
                          _t(lang, 'Subtotal', 'जम्मा'),
                          '$currencyCode ${nf.format(invoice.subtotal)}',
                        ),
                        _pdfKv(
                          _t(lang, 'Discount', 'छुट'),
                          '$currencyCode ${nf.format(invoice.discountAmount)}',
                        ),
                        _pdfKv(
                          _t(lang, 'VAT', 'भ्याट'),
                          '$currencyCode ${nf.format(invoice.taxAmount)}',
                        ),
                        pw.Divider(),
                        _pdfKv(
                          _t(lang, 'Total', 'कुल जम्मा'),
                          '$currencyCode ${nf.format(invoice.total)}',
                          bold: true,
                        ),
                        _pdfKv(
                          _t(lang, 'Paid', 'तिरेको'),
                          '$currencyCode ${nf.format(invoice.paidAmount)}',
                        ),
                        _pdfKv(
                          _t(lang, 'Balance', 'बाकी'),
                          '$currencyCode ${nf.format(invoice.balanceDue)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                if ((invoice.notes ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    _t(lang, 'Notes', 'नोट'),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.notes!.trim()),
                ],
                if (payments.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    _t(lang, 'Payments', 'भुक्तानीहरू'),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  ...payments.map(
                    (p) => pw.Text(
                      '${dateFmt.format(p.paidAt.toLocal())} • ${p.method} • $currencyCode ${nf.format(p.amount)}',
                    ),
                  ),
                ],
                if (terms.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    _t(lang, 'Terms', 'शर्तहरू'),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(terms),
                ],
                if (footer.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Divider(),
                  pw.Text(footer),
                ],
              ],
        ),
      );

      final bytes = await pdf.save();
      final file = await _invoiceFile(
        invoice.businessId,
        invoice.invoiceNumber,
        invoice.id,
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      await _repo.updateInvoicePdfArtifact(
        invoiceId: invoiceId,
        pdfPath: file.path,
        pdfStatus: 'generated',
      );
      return file.path;
    } catch (e) {
      await _repo.updateInvoicePdfArtifact(
        invoiceId: invoiceId,
        pdfPath: null,
        pdfStatus: 'failed',
      );
      throw StateError('PDF generation failed: $e');
    }
  }

  Future<void> shareInvoicePdf(String invoiceId) async {
    final invoice = await _repo.getInvoiceById(invoiceId);
    if (invoice == null) throw StateError('Invoice not found');
    final file = await _resolvePdfFile(invoice);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: invoice.invoiceNumber ?? 'Invoice',
      ),
    );
  }

  Future<void> printInvoicePdf(String invoiceId) async {
    final invoice = await _repo.getInvoiceById(invoiceId);
    if (invoice == null) throw StateError('Invoice not found');
    final file = await _resolvePdfFile(invoice);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<File> _resolvePdfFile(InvoiceRecord invoice) async {
    final path = invoice.pdfPath;
    if (path == null || path.isEmpty) {
      throw StateError('PDF not generated');
    }
    final file = File(path);
    if (!await file.exists()) throw StateError('PDF file missing');
    return file;
  }

  Future<File> _invoiceFile(
    String businessId,
    String? invoiceNumber,
    String invoiceId,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final safeName = _safeFileName(invoiceNumber ?? invoiceId);
    return File('${docs.path}/invoices/$businessId/$safeName.pdf');
  }

  String _safeFileName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'invoice';
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  }

  pw.Widget _pdfKv(String k, String v, {bool bold = false}) {
    final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(k), pw.Text(v, style: style)],
      ),
    );
  }

  NumberFormat get _currencyFormatter => NumberFormat('#,##0.00', 'en_IN');
  DateFormat get _dateFormatter => DateFormat('yyyy-MM-dd');

  String _t(String lang, String en, String ne) => lang == 'ne' ? ne : en;

  String _firstNonEmpty(String? a, String? b, {String fallback = ''}) {
    final primary = (a ?? '').trim();
    if (primary.isNotEmpty) return primary;
    final secondary = (b ?? '').trim();
    if (secondary.isNotEmpty) return secondary;
    return fallback;
  }
}
