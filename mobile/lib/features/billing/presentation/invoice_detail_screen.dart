import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/display_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));
    final itemsAsync = ref.watch(invoiceItemsProvider(widget.invoiceId));
    final paymentsAsync = ref.watch(invoicePaymentsProvider(widget.invoiceId));
    final money = NumberFormat('#,##0.00', 'en_IN');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.invoiceDetailTitle),
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
              title: l10n.invoiceDetailNotFound,
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
                                l10n.invoiceDetailDraftFallback,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.label,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: invoiceStatusLabel(context, invoice.status),
                          color: _statusColor(invoice.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _kv(
                      context,
                      l10n.invoiceIssueDateLabel,
                      invoice.issueDate == null
                          ? l10n.invoiceNotIssued
                          : DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(invoice.issueDate!.toLocal()),
                    ),
                    _kv(
                      context,
                      l10n.invoiceDueDateLabel,
                      invoice.dueDate == null
                          ? '-'
                          : DateFormat(
                            'yyyy-MM-dd',
                          ).format(invoice.dueDate!.toLocal()),
                    ),
                    _kv(
                      context,
                      l10n.subtotalLabel,
                      '${l10n.nprLabel} ${money.format(invoice.subtotal)}',
                    ),
                    _kv(
                      context,
                      l10n.discountLabel,
                      '${l10n.nprLabel} ${money.format(invoice.discountAmount)}',
                    ),
                    _kv(
                      context,
                      l10n.vatLabel,
                      '${l10n.nprLabel} ${money.format(invoice.taxAmount)}',
                    ),
                    const Divider(height: AppSpacing.lg * 2),
                    _kv(
                      context,
                      l10n.totalLabel,
                      '${l10n.nprLabel} ${money.format(invoice.total)}',
                      bold: true,
                    ),
                    _kv(
                      context,
                      l10n.paidLabel,
                      '${l10n.nprLabel} ${money.format(invoice.paidAmount)}',
                    ),
                    _kv(
                      context,
                      l10n.balanceLabel,
                      '${l10n.nprLabel} ${money.format(invoice.balanceDue)}',
                      bold: true,
                      valueColor:
                          invoice.balanceDue > 0
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    if ((invoice.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.notesLabel,
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
                      l10n.itemsLabel,
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
                            l10n.invoiceDetailNoItems,
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
                                  '${item.quantity} ${item.unitSnapshot ?? ''} × ${l10n.nprLabel} ${money.format(item.unitPrice)}',
                                ),
                                trailing: Text(
                                  '${l10n.nprLabel} ${money.format(item.lineTotal)}',
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
                      l10n.invoicePaymentsTitle,
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
                            l10n.invoicePaymentsEmpty,
                            style: const TextStyle(color: AppColors.muted),
                          );
                        }
                        return Column(
                          children: [
                            for (final p in payments) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.payments_outlined),
                                title: Text(paymentMethodLabel(context, p.method)),
                                subtitle: Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(p.paidAt.toLocal()),
                                ),
                                trailing: Text(
                                  '${l10n.nprLabel} ${money.format(p.amount)}',
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
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.actionsLabel,
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
                  label: Text(l10n.issueLabel),
                ),
              if (invoice.status != InvoiceStatus.cancelled &&
                  invoice.balanceDue > 0 &&
                  invoice.status != InvoiceStatus.draft)
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _recordPayment(context, invoice),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(l10n.invoiceRecordPaymentLabel),
                ),
              if (invoice.status != InvoiceStatus.cancelled &&
                  invoice.status != InvoiceStatus.draft)
                FilledButton.tonalIcon(
                  onPressed:
                      _busy ? null : () => _generatePdf(context, invoice),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    invoice.pdfStatus == 'failed'
                        ? l10n.invoicePdfRetry
                        : (invoice.pdfStatus == 'generated'
                            ? l10n.invoicePdfRegenerate
                            : l10n.invoicePdfGenerate),
                  ),
                ),
              if ((invoice.pdfPath ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _sharePdf(context),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.invoicePdfShare),
                ),
              if ((invoice.pdfPath ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _printPdf(context),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(l10n.printLabel),
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
      _showMessage(AppLocalizations.of(context)!.invoiceIssuedSuccess, BannerType.success);
    });
  }

  Future<void> _generatePdf(BuildContext context, InvoiceRecord invoice) async {
    await _runAction(context, () async {
      await ref.read(invoicePdfServiceProvider).generateInvoicePdf(invoice.id);
      _showMessage(AppLocalizations.of(context)!.invoicePdfGeneratedSuccess, BannerType.success);
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
    final l10n = AppLocalizations.of(context)!;
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
                  title: Text(l10n.invoiceRecordPaymentLabel),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.invoiceBalanceSummary(
                          '${l10n.nprLabel} ${invoice.balanceDue.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.amount,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: method,
                        items: [
                          DropdownMenuItem(
                            value: 'CASH',
                            child: Text(paymentMethodLabel(context, 'CASH')),
                          ),
                          DropdownMenuItem(
                            value: 'QR',
                            child: Text(paymentMethodLabel(context, 'QR')),
                          ),
                          DropdownMenuItem(
                            value: 'BANK',
                            child: Text(paymentMethodLabel(context, 'BANK')),
                          ),
                        ],
                        onChanged:
                            (v) => setStateDialog(() => method = v ?? 'CASH'),
                        decoration: InputDecoration(
                          labelText: l10n.paymentMethodLabelTitle,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: noteCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.noteOptionalLabel,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.save),
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
          AppLocalizations.of(context)!.invoiceEnterValidAmount,
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
          AppLocalizations.of(context)!.invoicePaymentRecordedSuccess,
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
