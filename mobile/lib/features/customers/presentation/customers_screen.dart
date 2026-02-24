import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../sales/presentation/credit_payment_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final customers = ref.watch(customersListProvider);

    return Column(
      children: [
        // ── search + add ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppColors.muted,
                    ),
                    hintText: 'Search customers…',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => const CustomerFormScreen(),
                    ))
                    .then((_) => ref.invalidate(customersListProvider)),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: Text(l10n.addCustomer),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
              ),
            ],
          ),
        ),

        // ── list ─────────────────────────────────────────────────────────
        Expanded(
          child: customers.when(
            loading: () => ListView.builder(
              itemCount: 6,
              itemBuilder: (_, __) => const SkeletonListTile(),
            ),
            error: (_, __) => ErrorRetry(
              onRetry: () => ref.invalidate(customersListProvider),
              message: 'Failed to load customers',
            ),
            data: (items) => items.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: l10n.manageCustomers,
                    subtitle: 'Tap "Add Customer" to get started.',
                    action: l10n.addCustomer,
                    onAction: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) => const CustomerFormScreen(),
                        ))
                        .then((_) => ref.invalidate(customersListProvider)),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(
                      indent: 72,
                      endIndent: AppSpacing.lg,
                      height: 0,
                    ),
                    itemBuilder: (_, i) {
                      final c = items[i];
                      final balance = c.balance;
                      final isDebt = balance > 0;
                      return Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.endToStart,
                        background: _DeleteBg(),
                        confirmDismiss: (_) => showConfirmDialog(
                          context,
                          title: 'Delete customer?',
                          body: '"${c.name}" will be permanently removed.',
                        ),
                        onDismissed: (_) {
                          ref.invalidate(customersListProvider);
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          leading: InitialsAvatar(name: c.name, size: 40),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.label,
                            ),
                          ),
                          subtitle: c.phone != null
                              ? Text(
                                  c.phone!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                )
                              : null,
                          trailing: balance != 0
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Rs ${balance.abs().toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDebt
                                                ? AppColors.warning
                                                : AppColors.success,
                                          ),
                                        ),
                                        Text(
                                          isDebt ? 'owes you' : 'credit',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDebt
                                                ? AppColors.warning
                                                : AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isDebt) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      IconButton(
                                        tooltip: 'Record payment',
                                        onPressed: () =>
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                                  builder: (_) =>
                                                      CreditPaymentScreen(
                                                    customerId: c.id,
                                                    customerName: c.name,
                                                    outstandingBalance:
                                                        c.balance,
                                                  ),
                                                ))
                                                .then((_) => ref.invalidate(
                                                    customersListProvider)),
                                        icon: const Icon(
                                          Icons.payments_outlined,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : null,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailScreen(customerId: c.id),
                            ),
                          ),
                          onLongPress: isDebt
                              ? () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) => CreditPaymentScreen(
                                      customerId: c.id,
                                      customerName: c.name,
                                      outstandingBalance: c.balance,
                                    ),
                                  ))
                                  .then((_) =>
                                      ref.invalidate(customersListProvider))
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _DeleteBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      color: AppColors.errorBg,
      child: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.error,
        size: 22,
      ),
    );
  }
}
