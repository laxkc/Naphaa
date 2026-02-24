import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../customers/domain/customer_risk_metric.dart';
import '../../customers/presentation/customer_detail_screen.dart';

class CreditReportScreen extends ConsumerWidget {
  const CreditReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(creditReportProvider);
    final riskMetricsAsync = ref.watch(customerRiskMetricsProvider);
    final currFmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Credit Report', 'उधारो रिपोर्ट')),
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
              title: context.tr(
                'No outstanding credit',
                'कुनै बाँकी उधारो छैन',
              ),
              subtitle: context.tr(
                'All customers are settled',
                'सबै ग्राहकको हिसाब मिलेको छ',
              ),
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
                            context.tr('Total Outstanding', 'कुल बाँकी उधारो'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.warning),
                          ),
                          Text(
                            'NPR ${currFmt.format(totalOutstanding)}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      context.tr(
                        '${customers.length} customer${customers.length != 1 ? 's' : ''}',
                        '${customers.length} ग्राहक',
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
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
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (c.phone != null)
                                  Text(
                                    c.phone!,
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
                          Text(
                            'NPR ${currFmt.format(c.balance)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
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
    final level = risk.riskLevel.toLowerCase();
    final (label, color) = switch (level) {
      'red' => ('High', AppColors.error),
      'yellow' => ('Medium', AppColors.warning),
      _ => ('Low', AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$label Risk • ${risk.riskScore}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
