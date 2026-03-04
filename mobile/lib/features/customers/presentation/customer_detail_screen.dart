import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/l10n/display_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/date/calendar_adapter.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../sales/presentation/credit_payment_screen.dart';
import '../domain/customer_risk_metric.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));
    final riskMetrics = ref.watch(customerRiskMetricsProvider);
    final currFmt = NumberFormat('#,##0.00');
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final calendarAsync = ref.watch(calendarAdapterProvider);
    final calendar =
        calendarAsync is AsyncData<CalendarAdapter>
            ? calendarAsync.value
            : CalendarAdapter(calendarMode: 'AD', localeCode: localeCode);
    final timeFmt = DateFormat('h:mm a');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.customerDetailsTitle),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: customerAsync.whenOrNull(
              data:
                  (customer) =>
                      customer == null
                          ? null
                          : () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => CustomerFormScreen(
                                        customer: customer,
                                      ),
                                ),
                              )
                              .then((_) {
                                ref.invalidate(
                                  customerDetailProvider(customerId),
                                );
                                ref.invalidate(customersListProvider);
                              }),
            ),
          ),
        ],
      ),
      body: customerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => ErrorRetry(
                onRetry:
                    () => ref.invalidate(customerDetailProvider(customerId)),
              ),
          data: (customer) {
            if (customer == null) {
              return EmptyState(
                icon: Icons.person_outline_rounded,
                title: l10n.customerNotFoundTitle,
                subtitle: l10n.customerNotFoundSubtitle,
              );
            }
            final hasDebt = customer.balance > 0;
            final risk = riskMetrics.whenOrNull(data: (m) => m[customer.id]);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
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
                                Text(
                                  customer.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (customer.phone != null)
                                  Text(
                                    customer.phone!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                if (customer.address != null)
                                  Text(
                                    customer.address!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.muted),
                                  ),
                                if (risk != null) ...[
                                  const SizedBox(height: 6),
                                  _RiskSummaryBadge(risk: risk),
                                ],
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
                                Text(
                                  l10n.outstandingBalanceLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.nprLabel} ${currFmt.format(customer.balance)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    color:
                                        hasDebt
                                            ? AppColors.warning
                                            : AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hasDebt) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.payments_outlined, size: 16),
                            label: Text(
                              l10n.recordPaymentLabel,
                            ),
                            onPressed:
                                () => Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => CreditPaymentScreen(
                                              customerId: customer.id,
                                              customerName: customer.name,
                                              outstandingBalance:
                                                  customer.balance,
                                            ),
                                      ),
                                    )
                                    .then((_) {
                                      ref.invalidate(
                                        customerDetailProvider(customerId),
                                      );
                                      ref.invalidate(
                                        customerLedgerProvider(customerId),
                                      );
                                      ref.invalidate(customersListProvider);
                                    }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (risk != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RiskExplanationPanel(risk: risk),
                ],

                const SizedBox(height: AppSpacing.lg),
                SectionHeader(l10n.transactionHistoryTitle),
                const SizedBox(height: AppSpacing.sm),

                ledgerAsync.when(
                  loading:
                      () => AppCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.loadingTransactions,
                              ),
                            ],
                          ),
                        ),
                      ),
                  error:
                      (_, __) => ErrorRetry(
                        onRetry:
                            () => ref.invalidate(
                              customerLedgerProvider(customerId),
                            ),
                        message: l10n.failedToLoadCustomerTransactions,
                      ),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return AppCard(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              l10n.noTransactionsYetTitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ),
                      );
                    }
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children:
                            entries.asMap().entries.map((e) {
                              final i = e.key;
                              final entry = e.value;
                              final isPayment =
                                  (entry['entry_type']
                                          ?.toString()
                                          .toUpperCase() ??
                                      '') ==
                                  'PAYMENT';
                              final amount = _toDouble(entry['amount']);
                              final date =
                                  entry['created_at'] is DateTime
                                      ? entry['created_at'] as DateTime
                                      : DateTime.tryParse(
                                            entry['created_at']?.toString() ??
                                                '',
                                          ) ??
                                          DateTime.now();

                              return Column(
                                children: [
                                  if (i > 0) const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.md,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color:
                                                isPayment
                                                    ? AppColors.successBg
                                                    : AppColors.warningBg,
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.sm,
                                            ),
                                          ),
                                          child: Icon(
                                            isPayment
                                                ? Icons.payments_outlined
                                                : Icons.shopping_cart_outlined,
                                            size: 16,
                                            color:
                                                isPayment
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
                                                    ? l10n.paymentReceivedLabel
                                                    : l10n.creditSaleLabel,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              Text(
                                                '${calendar.formatBusinessDate(date.toLocal())} • ${timeFmt.format(date.toLocal())}',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${isPayment ? '-' : '+'}${l10n.nprLabel} ${currFmt.format(amount)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isPayment
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
            );
          },
        ),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class _RiskSummaryBadge extends StatelessWidget {
  const _RiskSummaryBadge({required this.risk});

  final CustomerRiskMetric risk;

  @override
  Widget build(BuildContext context) {
    final level = risk.riskLevel.toLowerCase();
    final label = riskLevelLabel(context, level);
    final color = switch (level) {
      'red' => AppColors.error,
      'yellow' => AppColors.warning,
      _ => AppColors.success,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$label • ${risk.riskScore}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        if (risk.oldestDueDays > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              AppLocalizations.of(context)!.oldestDueChipDays(risk.oldestDueDays),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _RiskExplanationPanel extends StatelessWidget {
  const _RiskExplanationPanel({required this.risk});

  final CustomerRiskMetric risk;

  @override
  Widget build(BuildContext context) {
    final onTimePct = (risk.onTimeRate * 100).clamp(0, 100).toStringAsFixed(0);
    final level = risk.riskLevel.toLowerCase();
    final Color accent = switch (level) {
      'red' => AppColors.error,
      'yellow' => AppColors.warning,
      _ => AppColors.success,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, size: 18, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.riskExplanationTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _RiskReasonRow(
            label: AppLocalizations.of(context)!.oldestOverdueLabel,
            value: AppLocalizations.of(context)!.daysValue(risk.oldestDueDays),
            severity: _factorSeverity(risk.factors.oldestDueFactor),
          ),
          _RiskReasonRow(
            label: AppLocalizations.of(context)!.averageDaysToPayLabel,
            value: AppLocalizations.of(context)!.daysValueDecimal(
              risk.avgDaysToPay.toStringAsFixed(1),
            ),
            severity: _factorSeverity(risk.factors.avgDaysToPayFactor),
          ),
          _RiskReasonRow(
            label: AppLocalizations.of(context)!.onTimeRateLabel,
            value: '$onTimePct%',
            severity: _inverseFactorSeverity(risk.factors.lateBehaviorFactor),
          ),
          _RiskReasonRow(
            label: AppLocalizations.of(context)!.outstandingSpikeLabel,
            value: _spikeText(context, risk.factors.outstandingSpikeFactor),
            severity: _factorSeverity(risk.factors.outstandingSpikeFactor),
          ),
        ],
      ),
    );
  }
}

class _RiskReasonRow extends StatelessWidget {
  const _RiskReasonRow({
    required this.label,
    required this.value,
    required this.severity,
  });

  final String label;
  final String value;
  final _RiskSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (dotColor, textColor) = switch (severity) {
      _RiskSeverity.high => (AppColors.error, AppColors.error),
      _RiskSeverity.medium => (AppColors.warning, AppColors.warning),
      _RiskSeverity.low => (AppColors.success, AppColors.success),
      _RiskSeverity.neutral => (AppColors.muted, AppColors.muted),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum _RiskSeverity { high, medium, low, neutral }

_RiskSeverity _factorSeverity(double value) {
  if (value >= 0.66) return _RiskSeverity.high;
  if (value >= 0.33) return _RiskSeverity.medium;
  if (value > 0) return _RiskSeverity.low;
  return _RiskSeverity.neutral;
}

_RiskSeverity _inverseFactorSeverity(double lateBehaviorFactor) {
  if (lateBehaviorFactor >= 0.66) return _RiskSeverity.high;
  if (lateBehaviorFactor >= 0.33) return _RiskSeverity.medium;
  if (lateBehaviorFactor > 0) return _RiskSeverity.low;
  return _RiskSeverity.low;
}

String _spikeText(BuildContext context, double factor) {
  final l10n = AppLocalizations.of(context)!;
  if (factor >= 0.66) return l10n.highLabel;
  if (factor >= 0.33) return l10n.mediumLabel;
  if (factor > 0) return l10n.lowLabel;
  return l10n.normalLabel;
}
