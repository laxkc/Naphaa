import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../sales/presentation/credit_payment_screen.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));
    final currFmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, y · h:mm a');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: AppColors.surface,
        actions: [
          customerAsync.whenOrNull(
                data: (customer) => customer != null
                    ? IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                              builder: (_) =>
                                  CustomerFormScreen(customer: customer),
                            ))
                            .then((_) {
                          ref.invalidate(customerDetailProvider(customerId));
                          ref.invalidate(customersListProvider);
                        }),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
        data: (customer) {
          if (customer == null) {
            return const EmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Customer not found',
              subtitle: 'This customer may have been removed',
            );
          }
          final hasDebt = customer.balance > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primary
                                .withValues(alpha: 0.12),
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge),
                                if (customer.phone != null)
                                  Text(customer.phone!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                if (customer.address != null)
                                  Text(customer.address!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Outstanding Balance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  'NPR ${currFmt.format(customer.balance)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: hasDebt
                                            ? AppColors.warning
                                            : AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (hasDebt)
                            FilledButton.icon(
                              icon: const Icon(Icons.payments_outlined,
                                  size: 16),
                              label: const Text('Record Payment'),
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) => CreditPaymentScreen(
                                      customerId: customer.id,
                                      customerName: customer.name,
                                      outstandingBalance: customer.balance,
                                    ),
                                  ))
                                  .then((_) {
                                ref.invalidate(
                                    customerDetailProvider(customerId));
                                ref.invalidate(
                                    customerLedgerProvider(customerId));
                                ref.invalidate(customersListProvider);
                              }),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                SectionHeader('Transaction History'),
                const SizedBox(height: AppSpacing.sm),

                ledgerAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SkeletonListTile(),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return AppCard(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'No transactions yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ),
                      );
                    }
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: entries.asMap().entries.map((e) {
                          final i = e.key;
                          final entry = e.value;
                          final isPayment = entry['type'] == 'payment';
                          final amount =
                              (entry['amount'] as num).toDouble();
                          final date = entry['date'] is DateTime
                              ? entry['date'] as DateTime
                              : DateTime.tryParse(
                                      entry['date']?.toString() ?? '') ??
                                  DateTime.now();

                          return Column(
                            children: [
                              if (i > 0) const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isPayment
                                            ? AppColors.successBg
                                            : AppColors.warningBg,
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppRadius.sm),
                                      ),
                                      child: Icon(
                                        isPayment
                                            ? Icons.payments_outlined
                                            : Icons.shopping_cart_outlined,
                                        size: 16,
                                        color: isPayment
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isPayment
                                                ? 'Payment Received'
                                                : 'Credit Sale',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                          ),
                                          Text(
                                            dateFmt.format(
                                                date.toLocal()),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isPayment ? '-' : '+'}NPR ${currFmt.format(amount)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isPayment
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
