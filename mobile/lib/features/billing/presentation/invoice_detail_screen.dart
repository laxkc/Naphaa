import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/invoice_models.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _busy = false;
  String? _message;
  BannerType _messageType = BannerType.info;

  @override
  Widget build(BuildContext context) {
    final billingLangAsync = ref.watch(billingLanguageCodeProvider);
    final billingLang =
        billingLangAsync.asData?.value ??
        Localizations.localeOf(context).languageCode;
    return Localizations.override(
      context: context,
      locale: Locale(billingLang),
      child: Builder(builder: (context) => _buildScaffold(context)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));
    final itemsAsync = ref.watch(invoiceItemsProvider(widget.invoiceId));
    final paymentsAsync = ref.watch(invoicePaymentsProvider(widget.invoiceId));
    final money = NumberFormat('#,##0.00', 'en_IN');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Invoice Details', 'इनभ्वाइस विवरण')),
        backgroundColor: AppColors.surface,
      ),
      body: invoiceAsync.when(
        loading:
            () => ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 5,
              itemBuilder:
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SkeletonListTile(),
                  ),
            ),
        error:
            (e, _) => ErrorRetry(
              message: e.toString(),
              onRetry: () {
                ref.invalidate(invoiceDetailProvider(widget.invoiceId));
                ref.invalidate(invoiceItemsProvider(widget.invoiceId));
                ref.invalidate(invoicePaymentsProvider(widget.invoiceId));
              },
            ),
        data: (invoice) {
          if (invoice == null) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: context.tr('Invoice not found', 'इनभ्वाइस भेटिएन'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (_message != null) ...[
                InlineBanner(message: _message!, type: _messageType),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber ??
                                context.tr('Draft Invoice', 'ड्राफ्ट इनभ्वाइस'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.label,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: invoice.status.name.toUpperCase(),
                          color: _statusColor(invoice.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _kv(
                      context,
                      context.tr('Issue Date', 'जारी मिति'),
                      invoice.issueDate == null
                          ? context.tr('Not issued', 'जारी गरिएको छैन')
                          : DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(invoice.issueDate!.toLocal()),
                    ),
                    _kv(
                      context,
                      context.tr('Due Date', 'बुझाउने मिति'),
                      invoice.dueDate == null
                          ? '-'
                          : DateFormat(
                            'yyyy-MM-dd',
                          ).format(invoice.dueDate!.toLocal()),
                    ),
                    _kv(
                      context,
                      context.tr('Subtotal', 'जम्मा'),
                      'NPR ${money.format(invoice.subtotal)}',
                    ),
                    _kv(
                      context,
                      context.tr('Discount', 'छुट'),
                      'NPR ${money.format(invoice.discountAmount)}',
                    ),
                    _kv(
                      context,
                      context.tr('VAT', 'भ्याट'),
                      'NPR ${money.format(invoice.taxAmount)}',
                    ),
                    const Divider(height: AppSpacing.lg * 2),
                    _kv(
                      context,
                      context.tr('Total', 'कुल जम्मा'),
                      'NPR ${money.format(invoice.total)}',
                      bold: true,
                    ),
                    _kv(
                      context,
                      context.tr('Paid', 'तिरेको'),
                      'NPR ${money.format(invoice.paidAmount)}',
                    ),
                    _kv(
                      context,
                      context.tr('Balance', 'बाकी'),
                      'NPR ${money.format(invoice.balanceDue)}',
                      bold: true,
                      valueColor:
                          invoice.balanceDue > 0
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    if ((invoice.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.tr('Notes', 'नोट'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        invoice.notes!,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildActions(context, invoice),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Items', 'सामानहरू'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    itemsAsync.when(
                      loading:
                          () => const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      error:
                          (e, _) => Text(
                            e.toString(),
                            style: const TextStyle(color: AppColors.error),
                          ),
                      data: (items) {
                        if (items.isEmpty) {
                          return Text(
                            context.tr('No items', 'कुनै सामान छैन'),
                            style: const TextStyle(color: AppColors.muted),
                          );
                        }
                        return Column(
                          children: [
                            for (final item in items) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.productNameSnapshot),
                                subtitle: Text(
                                  '${item.quantity} ${item.unitSnapshot ?? ''} × NPR ${money.format(item.unitPrice)}',
                                ),
                                trailing: Text(
                                  'NPR ${money.format(item.lineTotal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (item != items.last) const Divider(height: 1),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Payments', 'भुक्तानीहरू'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    paymentsAsync.when(
                      loading:
                          () => const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      error:
                          (e, _) => Text(
                            e.toString(),
                            style: const TextStyle(color: AppColors.error),
                          ),
                      data: (payments) {
                        if (payments.isEmpty) {
                          return Text(
                            context.tr(
                              'No payments recorded',
                              'भुक्तानी रेकर्ड छैन',
                            ),
                            style: const TextStyle(color: AppColors.muted),
                          );
                        }
                        return Column(
                          children: [
                            for (final p in payments) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.payments_outlined),
                                title: Text(p.method),
                                subtitle: Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(p.paidAt.toLocal()),
                                ),
                                trailing: Text(
                                  'NPR ${money.format(p.amount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (p.note != null && p.note!.trim().isNotEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      p.note!,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              if (p != payments.last) const Divider(height: 1),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, InvoiceRecord invoice) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Actions', 'कार्यहरू'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (invoice.status == InvoiceStatus.draft)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _issueInvoice(context),
                  icon: const Icon(Icons.task_alt_outlined),
                  label: Text(context.tr('Issue', 'जारी गर्नुहोस्')),
                ),
              if (invoice.status != InvoiceStatus.cancelled &&
                  invoice.balanceDue > 0 &&
                  invoice.status != InvoiceStatus.draft)
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _recordPayment(context, invoice),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(context.tr('Record Payment', 'भुक्तानी रेकर्ड')),
                ),
              if (invoice.status != InvoiceStatus.cancelled &&
                  invoice.status != InvoiceStatus.draft)
                FilledButton.tonalIcon(
                  onPressed:
                      _busy ? null : () => _generatePdf(context, invoice),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    invoice.pdfStatus == 'failed'
                        ? context.tr('Retry PDF', 'PDF पुन: प्रयास')
                        : (invoice.pdfStatus == 'generated'
                            ? context.tr(
                              'Regenerate PDF',
                              'PDF पुन: बनाउनुहोस्',
                            )
                            : context.tr('Generate PDF', 'PDF बनाउनुहोस्')),
                  ),
                ),
              if ((invoice.pdfPath ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _sharePdf(context),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(context.tr('Share PDF', 'PDF सेयर')),
                ),
              if ((invoice.pdfPath ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _printPdf(context),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(context.tr('Print', 'प्रिन्ट')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _issueInvoice(BuildContext context) async {
    await _runAction(context, () async {
      await ref
          .read(billingRepositoryProvider)
          .issueInvoice(invoiceId: widget.invoiceId);
      _showMessage(
        context.tr(
          'Invoice issued successfully',
          'इनभ्वाइस सफलतापूर्वक जारी भयो',
        ),
        BannerType.success,
      );
    });
  }

  Future<void> _generatePdf(BuildContext context, InvoiceRecord invoice) async {
    await _runAction(context, () async {
      await ref.read(invoicePdfServiceProvider).generateInvoicePdf(invoice.id);
      _showMessage(
        context.tr('PDF generated successfully', 'PDF सफलतापूर्वक बन्यो'),
        BannerType.success,
      );
    });
  }

  Future<void> _sharePdf(BuildContext context) async {
    await _runAction(context, () async {
      await ref
          .read(invoicePdfServiceProvider)
          .shareInvoicePdf(widget.invoiceId);
    });
  }

  Future<void> _printPdf(BuildContext context) async {
    await _runAction(context, () async {
      await ref
          .read(invoicePdfServiceProvider)
          .printInvoicePdf(widget.invoiceId);
    });
  }

  Future<void> _recordPayment(
    BuildContext context,
    InvoiceRecord invoice,
  ) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String method = 'CASH';
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => StatefulBuilder(
              builder: (ctx, setStateDialog) {
                return AlertDialog(
                  title: Text(context.tr('Record Payment', 'भुक्तानी रेकर्ड')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${context.tr('Balance', 'बाकी')}: NPR ${invoice.balanceDue.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('Amount', 'रकम'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: method,
                        items: const [
                          DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                          DropdownMenuItem(value: 'QR', child: Text('QR')),
                          DropdownMenuItem(value: 'BANK', child: Text('BANK')),
                        ],
                        onChanged:
                            (v) => setStateDialog(() => method = v ?? 'CASH'),
                        decoration: InputDecoration(
                          labelText: context.tr('Method', 'विधि'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: noteCtrl,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'Note (optional)',
                            'नोट (वैकल्पिक)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(context.tr('Cancel', 'रद्द गर्नुहोस्')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(context.tr('Save', 'सेभ')),
                    ),
                  ],
                );
              },
            ),
      );

      if (confirmed != true) return;
      final amount = double.tryParse(amountCtrl.text.trim());
      if (amount == null || amount <= 0) {
        _showMessage(
          context.tr('Enter a valid amount', 'सही रकम हाल्नुहोस्'),
          BannerType.error,
        );
        return;
      }

      await _runAction(context, () async {
        await ref
            .read(billingRepositoryProvider)
            .recordPayment(
              invoiceId: widget.invoiceId,
              input: InvoicePaymentInput(
                amount: amount,
                method: method,
                note:
                    noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              ),
            );
        _showMessage(
          context.tr('Payment recorded', 'भुक्तानी रेकर्ड भयो'),
          BannerType.success,
        );
      });
    } finally {
      amountCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      ref.invalidate(invoicesListProvider);
      ref.invalidate(invoiceDetailProvider(widget.invoiceId));
      ref.invalidate(invoiceItemsProvider(widget.invoiceId));
      ref.invalidate(invoicePaymentsProvider(widget.invoiceId));
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e.toString().replaceFirst('Bad state: ', ''),
        BannerType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String text, BannerType type) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _messageType = type;
    });
  }

  Widget _kv(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.label,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(InvoiceStatus status) => switch (status) {
    InvoiceStatus.draft => AppColors.muted,
    InvoiceStatus.issued => AppColors.primary,
    InvoiceStatus.paid => AppColors.success,
    InvoiceStatus.overdue => AppColors.error,
    InvoiceStatus.cancelled => AppColors.warning,
  };
}
