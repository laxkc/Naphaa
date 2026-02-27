import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/display_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../customers/domain/customer_risk_metric.dart';
import '../../customers/presentation/customer_detail_screen.dart';

class CreditReportScreen extends ConsumerWidget {
  const CreditReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(creditReportProvider);
    final riskMetricsAsync = ref.watch(customerRiskMetricsProvider);
    final currFmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.reportsCreditReportTitle),
        backgroundColor: AppColors.surface,
      ),
      body: reportAsync.when(
        loading:
            () => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 6,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, __) => const SkeletonListTile(),
            ),
        error:
            (e, _) =>
                ErrorRetry(onRetry: () => ref.invalidate(creditReportProvider)),
        data: (customers) {
          if (customers.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.creditReportNoOutstandingTitle,
              subtitle: l10n.creditReportNoOutstandingSubtitle,
            );
          }
          final totalOutstanding = customers.fold<double>(
            0,
            (sum, c) => sum + c.balance,
          );
          return Column(
            children: [
              Container(
                color: AppColors.warningBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.creditReportTotalOutstanding,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.warning),
                          ),
                          Text(
                            '${l10n.nprLabel} ${currFmt.format(totalOutstanding)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.creditReportCustomerCount(customers.length),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: customers.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final c = customers[i];
                    final risk = riskMetricsAsync.whenOrNull(
                      data: (m) => m[c.id],
                    );
                    return AppCard(
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => CustomerDetailScreen(customerId: c.id),
                            ),
                          ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.warningBg,
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (c.phone != null)
                                  Text(
                                    c.phone!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                if (risk != null) ...[
                                  const SizedBox(height: 4),
                                  _CreditRiskBadge(risk: risk),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 84,
                            child: Text(
                              '${l10n.nprLabel} ${currFmt.format(c.balance)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreditRiskBadge extends StatelessWidget {
  const _CreditRiskBadge({required this.risk});

  final CustomerRiskMetric risk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final level = risk.riskLevel.toLowerCase();
    final label = riskLevelLabel(context, level, short: true);
    final color = switch (level) {
      'red' => AppColors.error,
      'yellow' => AppColors.warning,
      _ => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '${l10n.creditReportRiskBadge(label)} • ${risk.riskScore}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
