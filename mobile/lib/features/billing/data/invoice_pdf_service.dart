import 'dart:io';
import 'dart:ui' show Locale;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/date/calendar_adapter.dart';
import '../../../core/storage/preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/invoice_models.dart';
import 'billing_repository.dart';

class InvoicePdfService {
  InvoicePdfService(
    this._repo,
    this._prefs, {
    Future<CalendarAdapter> Function()? calendarAdapterLoader,
  }) : _calendarAdapterLoader = calendarAdapterLoader;

  final BillingRepository _repo;
  final AppPreferences _prefs;
  final Future<CalendarAdapter> Function()? _calendarAdapterLoader;

  Future<String> generateInvoicePdf(String invoiceId) async {
    final invoice = await _repo.getInvoiceById(invoiceId);
    if (invoice == null) throw StateError('Invoice not found');
    final items = await _repo.getInvoiceItems(invoiceId);
    final payments = await _repo.getInvoicePayments(invoiceId);
    if (items.isEmpty) throw StateError('Invoice has no items');

    try {
      final settings = await _prefs.getBillingSettings();
      final adapter =
          _calendarAdapterLoader == null
              ? CalendarAdapter(
                calendarMode: await _prefs.getCalendarMode(),
                localeCode: settings['language']?.toString() ?? 'en',
              )
              : await _calendarAdapterLoader.call();
      final pdf = pw.Document();
      final nf = _currencyFormatter;
      final lang =
          (invoice.languageSnapshot.trim().isNotEmpty
                  ? invoice.languageSnapshot
                  : (settings['language']?.toString() ?? 'en'))
              .toLowerCase();
      final l10n = lookupAppLocalizations(Locale(lang == 'ne' ? 'ne' : 'en'));
      final currencyCode =
          invoice.currencyCode.trim().isNotEmpty ? invoice.currencyCode : 'NPR';
      final businessName = _firstNonEmpty(
        invoice.businessNameSnapshot,
        settings['business_name']?.toString(),
        fallback: l10n.businessLabel,
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
                              '${l10n.phone}: $businessPhone',
                            ),
                          if (businessEmail.isNotEmpty)
                            pw.Text(
                              '${l10n.emailLabel}: $businessEmail',
                            ),
                          if (panVat.isNotEmpty)
                            pw.Text(
                              '${l10n.panVatLabel}: $panVat',
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          l10n.invoicePdfTitle,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          invoice.invoiceNumber ?? l10n.draftLabel,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${l10n.dateLabel}: ${adapter.formatBusinessDate(invoice.issueDateAd ?? invoice.issueDate ?? DateTime.now())}',
                        ),
                        if (invoice.dueDateAd != null || invoice.dueDate != null)
                          pw.Text(
                            '${l10n.invoiceDueShortLabel}: ${adapter.formatBusinessDate(invoice.dueDateAd ?? invoice.dueDate)}',
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
                    l10n.itemLabel,
                    l10n.qtyLabel,
                    l10n.rateLabel,
                    l10n.totalLabel,
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
                          l10n.subtotalLabel,
                          '$currencyCode ${nf.format(invoice.subtotal)}',
                        ),
                        _pdfKv(
                          l10n.discountLabel,
                          '$currencyCode ${nf.format(invoice.discountAmount)}',
                        ),
                        _pdfKv(
                          l10n.vatLabel,
                          '$currencyCode ${nf.format(invoice.taxAmount)}',
                        ),
                        pw.Divider(),
                        _pdfKv(
                          l10n.totalLabel,
                          '$currencyCode ${nf.format(invoice.total)}',
                          bold: true,
                        ),
                        _pdfKv(
                          l10n.paidLabel,
                          '$currencyCode ${nf.format(invoice.paidAmount)}',
                        ),
                        _pdfKv(
                          l10n.balanceLabel,
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
                    l10n.notesLabel,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.notes!.trim()),
                ],
                if (payments.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    l10n.paymentsLabel,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  ...payments.map(
                    (p) => pw.Text(
                      '${adapter.formatBusinessDate(p.paidAt, includeTime: true)} • ${p.method} • $currencyCode ${nf.format(p.amount)}',
                    ),
                  ),
                ],
                if (terms.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    l10n.termsLabel,
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
      throw StateError('${lookupAppLocalizations(const Locale('en')).pdfGenerationFailedPrefix}: $e');
    }
  }

  Future<void> shareInvoicePdf(String invoiceId) async {
    final invoice = await _repo.getInvoiceById(invoiceId);
    if (invoice == null) throw StateError('Invoice not found');
    final file = await _resolvePdfFile(invoice);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: invoice.invoiceNumber ?? lookupAppLocalizations(const Locale('en')).invoiceLabel,
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

  String _firstNonEmpty(String? a, String? b, {String fallback = ''}) {
    final primary = (a ?? '').trim();
    if (primary.isNotEmpty) return primary;
    final secondary = (b ?? '').trim();
    if (secondary.isNotEmpty) return secondary;
    return fallback;
  }
}
