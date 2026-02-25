import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/context_i18n.dart';
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Invoices', 'इनभ्वाइसहरू')),
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
        label: Text(context.tr('New Invoice', 'नयाँ इनभ्वाइस')),
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
              title: context.tr('No invoices yet', 'अहिलेसम्म इनभ्वाइस छैन'),
              subtitle: context.tr(
                'Create your first invoice and issue it offline.',
                'पहिलो इनभ्वाइस बनाउनुहोस् र अफलाइनमै जारी गर्नुहोस्।',
              ),
              action: context.tr('Create Invoice', 'इनभ्वाइस बनाउनुहोस्'),
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

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final inv = invoices[i];
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
                            inv.invoiceNumber ?? context.tr('Draft', 'ड्राफ्ट'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.label,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: inv.status.name.toUpperCase(),
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${context.tr('Total', 'कुल')}: NPR ${money.format(inv.total)}'
                      '   •   ${context.tr('Balance', 'बाकी')}: NPR ${money.format(inv.balanceDue)}',
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
                          : context.tr(
                            'Draft (not issued)',
                            'ड्राफ्ट (जारी गरिएको छैन)',
                          ),
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
