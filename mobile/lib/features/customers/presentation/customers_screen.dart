import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/l10n/display_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../sales/presentation/credit_payment_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customers = ref.watch(customersListProvider);
    final riskMetrics = ref.watch(customerRiskMetricsProvider);

    final content = Column(
      children: [
        // ── search + add ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppColors.muted,
                    ),
                    hintText: l10n.searchCustomersHint,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed:
                    () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerFormScreen(),
                          ),
                        )
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
            loading:
                () => ListView.builder(
                  itemCount: 6,
                  itemBuilder: (_, __) => const SkeletonListTile(),
                ),
            error:
                (_, __) => ErrorRetry(
                  onRetry: () => ref.invalidate(customersListProvider),
                  message: l10n.failedToLoadCustomers,
                ),
            data: (items) {
              final q = _query.trim().toLowerCase();
              final filtered =
                  q.isEmpty
                      ? items
                      : items.where((c) {
                        final name = c.name.toLowerCase();
                        final phone = (c.phone ?? '').toLowerCase();
                        return name.contains(q) || phone.contains(q);
                      }).toList();

              return filtered.isEmpty
                  ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    title:
                        q.isEmpty
                            ? l10n.manageCustomers
                            : l10n.noCustomersFoundTitle,
                    subtitle:
                        q.isEmpty
                            ? l10n.customersEmptySubtitle
                            : l10n.customersTryDifferentSearchSubtitle,
                    action: q.isEmpty ? l10n.addCustomer : null,
                    onAction:
                        q.isEmpty
                            ? () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => const CustomerFormScreen(),
                                  ),
                                )
                                .then(
                                  (_) => ref.invalidate(customersListProvider),
                                )
                            : null,
                  )
                  : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                          indent: 72,
                          endIndent: AppSpacing.lg,
                          height: 0,
                        ),
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final risk = riskMetrics.whenOrNull(data: (m) => m[c.id]);
                      final balance = c.balance;
                      final isDebt = balance > 0;
                      return Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.endToStart,
                        background: _DeleteBg(),
                        confirmDismiss:
                            (_) => showConfirmDialog(
                              context,
                              title: l10n.deleteCustomerDialogTitle,
                              body: l10n.customerDeletePermanentBody(c.name),
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
                          subtitle:
                              (c.phone != null || risk != null)
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (c.phone != null)
                                        Text(
                                          c.phone!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      if (risk != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: _RiskBadge(
                                            level: risk.riskLevel,
                                            score: risk.riskScore,
                                          ),
                                        ),
                                    ],
                                  )
                                  : null,
                          trailing:
                              balance != 0
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
                                              color:
                                                  isDebt
                                                      ? AppColors.warning
                                                      : AppColors.success,
                                            ),
                                          ),
                                          Text(
                                            isDebt
                                                ? l10n.owesYouLabel
                                                : l10n.creditLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color:
                                                  isDebt
                                                      ? AppColors.warning
                                                      : AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isDebt) ...[
                                        const SizedBox(width: AppSpacing.xs),
                                        IconButton(
                                          tooltip: l10n.recordPaymentTooltip,
                                          onPressed:
                                              () => Navigator.of(context)
                                                  .push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            _,
                                                          ) => CreditPaymentScreen(
                                                            customerId: c.id,
                                                            customerName:
                                                                c.name,
                                                            outstandingBalance:
                                                                c.balance,
                                                          ),
                                                    ),
                                                  )
                                                  .then(
                                                    (_) => ref.invalidate(
                                                      customersListProvider,
                                                    ),
                                                  ),
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
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => CustomerDetailScreen(
                                        customerId: c.id,
                                      ),
                                ),
                              ),
                          onLongPress:
                              isDebt
                                  ? () => Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => CreditPaymentScreen(
                                                customerId: c.id,
                                                customerName: c.name,
                                                outstandingBalance: c.balance,
                                              ),
                                        ),
                                      )
                                      .then(
                                        (_) => ref.invalidate(
                                          customersListProvider,
                                        ),
                                      )
                                  : null,
                        ),
                      );
                    },
                  );
            },
          ),
        ),
      ],
    );

    if (!widget.standalone) return content;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.customers),
        backgroundColor: AppColors.surface,
      ),
      body: content,
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.level, required this.score});

  final String level;
  final int score;

  @override
  Widget build(BuildContext context) {
    final normalized = level.toLowerCase();
    final (label, color) = switch (normalized) {
      'red' => (riskLevelLabel(context, 'red'), AppColors.error),
      'yellow' => (riskLevelLabel(context, 'yellow'), AppColors.warning),
      _ => (riskLevelLabel(context, 'green'), AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$label • $score',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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
