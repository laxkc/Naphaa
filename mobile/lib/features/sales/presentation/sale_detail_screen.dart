import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/core/l10n/display_labels.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/date/calendar_adapter.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/sale.dart';

class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.saleId});
  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final calendarAsync = ref.watch(calendarAdapterProvider);
    final calendar =
        calendarAsync is AsyncData<CalendarAdapter>
            ? calendarAsync.value
            : CalendarAdapter(calendarMode: 'AD', localeCode: localeCode);
    final timeFmt = DateFormat('h:mm a');
    final currFmt = NumberFormat('#,##0.00');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.saleDetailsTitle),
        backgroundColor: AppColors.surface,
      ),
      body: saleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              onRetry: () => ref.invalidate(saleDetailProvider(saleId)),
            ),
        data: (sale) {
          if (sale == null) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.saleNotFoundTitle,
              subtitle: l10n.saleNotFoundSubtitle,
            );
          }
          final isCash = sale.paymentMethod.toUpperCase() == 'CASH';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sale.customerName ?? l10n.walkInCustomer,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusChip(
                            label: saleStatusLabel(context, sale.status.name),
                            color: _statusColor(sale.status),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusChip(
                            label: paymentMethodLabel(
                              context,
                              sale.paymentMethod,
                            ),
                            color:
                                isCash ? AppColors.success : AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${calendar.formatBusinessDate(sale.createdAt.toLocal())} • ${timeFmt.format(sale.createdAt.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: AppSpacing.h),
                      Text(
                        l10n.totalAmountLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.nprLabel} ${currFmt.format(sale.totalAmount)}',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sale.items.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(l10n.itemsLabel),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      children: [
                        ...sale.items.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          return Column(
                            children: [
                              if (i > 0) const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${item.qty} × ${l10n.nprLabel} ${currFmt.format(item.unitPrice)}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${l10n.nprLabel} ${currFmt.format(item.lineTotal)}',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.totalLabel,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '${l10n.nprLabel} ${currFmt.format(sale.totalAmount)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (sale.payments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(l10n.paymentsLabel),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      children:
                          sale.payments.asMap().entries.map((e) {
                            final i = e.key;
                            final p = e.value;
                            return Column(
                              children: [
                                if (i > 0) const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _paymentIcon(p.method),
                                        size: 18,
                                        color: AppColors.muted,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          paymentMethodLabel(context, p.method),
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        '${l10n.nprLabel} ${currFmt.format(p.amount)}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _CorrectionActionsCard(
                  sale: sale,
                  onVoid: () => _handleVoid(context, ref, sale.id),
                  onRefund: () => _handleRefund(context, ref, sale),
                ),
                const SizedBox(height: AppSpacing.h),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _paymentIcon(String method) => switch (method) {
    'CASH' => Icons.payments_outlined,
    'QR' => Icons.qr_code_outlined,
    'BANK' => Icons.account_balance_outlined,
    'WALLET' => Icons.account_balance_wallet_outlined,
    'CREDIT' => Icons.credit_card_outlined,
    _ => Icons.attach_money,
  };

  Color _statusColor(SaleStatus status) => switch (status) {
    SaleStatus.completed => AppColors.success,
    SaleStatus.partial => AppColors.warning,
    SaleStatus.refunded => AppColors.muted,
    SaleStatus.voided => AppColors.error,
  };

  Future<void> _handleVoid(
    BuildContext context,
    WidgetRef ref,
    String saleId,
  ) async {
    final reason = await _askReason(context, title: 'Void Sale');
    if (reason == null) return;
    try {
      await ref
          .read(salesRepositoryProvider)
          .voidSale(saleId: saleId, reason: reason);
      ref.invalidate(saleDetailProvider(saleId));
      ref.invalidate(salesListProvider(const SalesListParams()));
      ref.invalidate(productsListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(customersListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale voided successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to void sale: $e')));
    }
  }

  Future<void> _handleRefund(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
  ) async {
    if (sale.items.isEmpty) return;
    final reason = await _askReason(context, title: 'Refund Sale');
    if (reason == null) return;
    final fullRefundItems = <String, double>{
      for (final item in sale.items) item.id: item.qty,
    };
    try {
      await ref
          .read(salesRepositoryProvider)
          .refundSale(
            saleId: sale.id,
            reason: reason,
            itemQtyBySaleItemId: fullRefundItems,
          );
      ref.invalidate(saleDetailProvider(sale.id));
      ref.invalidate(salesListProvider(const SalesListParams()));
      ref.invalidate(productsListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(customersListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale refund saved successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to refund sale: $e')));
    }
  }

  Future<String?> _askReason(
    BuildContext context, {
    required String title,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ctl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: ctl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.reasonLabel,
                hintText: 'Enter reason',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final value = ctl.text.trim();
                  if (value.isEmpty) return;
                  Navigator.of(ctx).pop(value);
                },
                child: Text(l10n.save),
              ),
            ],
          ),
    );
    ctl.dispose();
    return reason;
  }
}

class _CorrectionActionsCard extends StatelessWidget {
  const _CorrectionActionsCard({
    required this.sale,
    required this.onVoid,
    required this.onRefund,
  });

  final Sale sale;
  final VoidCallback onVoid;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final isVoided = sale.status == SaleStatus.voided;
    final canVoid = sale.status == SaleStatus.completed;
    final canRefund = !isVoided;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Corrections',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canVoid ? onVoid : null,
                  icon: const Icon(Icons.block),
                  label: const Text('Void Sale'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canRefund ? onRefund : null,
                  icon: const Icon(Icons.assignment_return),
                  label: const Text('Refund Sale'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
