import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/l10n/display_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/invoice_models.dart';
import 'invoice_create_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingLangAsync = ref.watch(billingLanguageCodeProvider);
    final billingLang =
        billingLangAsync.asData?.value ??
        Localizations.localeOf(context).languageCode;
    return Localizations.override(
      context: context,
      locale: Locale(billingLang),
      child: Builder(builder: (context) => _buildScaffold(context, ref)),
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesListProvider);
    final money = NumberFormat('#,##0.00', 'en_IN');
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.invoices),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const InvoiceCreateScreen()),
          );
          if (created != null && context.mounted) {
            ref.invalidate(invoicesListProvider);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoiceDetailScreen(invoiceId: created),
              ),
            );
          }
        },
        icon: const Icon(Icons.receipt_long_outlined),
        label: Text(l10n.invoiceListNewInvoice),
      ),
      body: invoicesAsync.when(
        loading:
            () => ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 6,
              itemBuilder:
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SkeletonListTile(),
                  ),
            ),
        error:
            (e, _) => ErrorRetry(
              onRetry: () => ref.invalidate(invoicesListProvider),
              message: e.toString(),
            ),
        data: (invoices) {
          if (invoices.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.invoiceListNoInvoicesTitle,
              subtitle: l10n.invoiceListNoInvoicesSubtitle,
              action: l10n.invoiceListCreateInvoiceAction,
              onAction: () async {
                final created = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => const InvoiceCreateScreen(),
                  ),
                );
                if (created != null) ref.invalidate(invoicesListProvider);
              },
            );
          }

          final totalBalance = invoices.fold<double>(
            0,
            (sum, inv) => sum + inv.balanceDue,
          );
          final overdueCount =
              invoices.where((inv) => inv.status == InvoiceStatus.overdue).length;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: invoices.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              if (i == 0) {
                return AppCard(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width > 380 ? 96 : 88,
                        child: _SummaryMetric(
                          label: l10n.invoices,
                          value: '${invoices.length}',
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width > 380 ? 160 : 136,
                        child: _SummaryMetric(
                          label: l10n.balanceLabel,
                          value: '${l10n.nprLabel} ${money.format(totalBalance)}',
                          color: AppColors.warning,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width > 380 ? 120 : 104,
                        child: _SummaryMetric(
                          label: l10n.invoiceStatusOverdueLabel,
                          value: '$overdueCount',
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final inv = invoices[i - 1];
              final statusColor = _statusColor(inv.status);
              return AppCard(
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetailScreen(invoiceId: inv.id),
                      ),
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inv.invoiceNumber ?? l10n.invoiceListDraftFallback,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.label,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: invoiceStatusLabel(context, inv.status),
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${l10n.totalLabel}: ${l10n.nprLabel} ${money.format(inv.total)}   •   ${l10n.balanceLabel}: ${l10n.nprLabel} ${money.format(inv.balanceDue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      inv.issueDate != null
                          ? DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(inv.issueDate!.toLocal())
                          : l10n.invoiceListDraftNotIssued,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
