import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/core/l10n/display_labels.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.saleId});
  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final fmt = DateFormat('MMMM d, yyyy · h:mm a');
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
          final isCash = sale.saleType == 'CASH';
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
                              sale.customerName ??
                                  l10n.walkInCustomer,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusChip(
                            label: paymentMethodLabel(context, sale.saleType),
                            color:
                                isCash ? AppColors.success : AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        fmt.format(sale.createdAt.toLocal()),
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
    'CREDIT' => Icons.credit_card_outlined,
    _ => Icons.attach_money,
  };
}
