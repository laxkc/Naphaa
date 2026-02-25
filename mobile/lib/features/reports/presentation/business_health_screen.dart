import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../customers/presentation/customer_detail_screen.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../domain/product_metric_item.dart';
import 'alert_action_router.dart';

class BusinessHealthScreen extends ConsumerWidget {
  const BusinessHealthScreen({super.key});

  static const _riskParams = CustomerMetricsQueryParams(limit: 500);
  static const _productParams = ProductMetricsQueryParams(
    limit: 200,
    windowDays: 30,
    deadStockDays: 30,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessMetricsProvider);
    final riskAsync = ref.watch(customerMetricsReportProvider(_riskParams));
    final alertsAsync = ref.watch(alertsFeedProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final productMetricsAsync = ref.watch(
      productMetricsReportProvider(_productParams),
    );
    final currFmt = NumberFormat('#,##0.00');
    final l10n = AppLocalizations.of(context)!;
    String? sourceOf(AsyncValue<Map<String, dynamic>> async) =>
        async.whenOrNull(data: (data) => data['source']?.toString());
    final usingCachedData =
        (sourceOf(businessAsync) == 'local_cache') ||
        (sourceOf(riskAsync) == 'local_cache') ||
        (sourceOf(productMetricsAsync) == 'local_cache');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.businessHealth),
        backgroundColor: AppColors.surface,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(businessMetricsProvider);
          ref.invalidate(customerMetricsReportProvider(_riskParams));
          ref.invalidate(alertsFeedProvider);
          ref.invalidate(lowStockProductsProvider);
          ref.invalidate(productMetricsReportProvider(_productParams));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (usingCachedData) ...[
              _CachedMetricsHintCard(
                message: l10n.businessHealthCachedDataBanner,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            SectionHeader(l10n.businessHealthProfitSnapshotTitle),
            const SizedBox(height: AppSpacing.sm),
            businessAsync.when(
              loading: () => const SkeletonListTile(),
              error:
                  (_, __) => ErrorRetry(
                    onRetry: () => ref.invalidate(businessMetricsProvider),
                  ),
              data: (summary) {
                final reasons =
                    (summary['reasons'] as List? ?? const [])
                        .map((e) => e.toString())
                        .where((e) => e.trim().isNotEmpty)
                        .take(2)
                        .toList();
                return AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.sales,
                              value:
                                  'NPR ${currFmt.format(_toDouble(summary['sales_total']))}',
                              color: AppColors.success,
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.expenses,
                              value:
                                  'NPR ${currFmt.format(_toDouble(summary['expenses_total']))}',
                              color: AppColors.error,
                              icon: Icons.receipt_long_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.businessHealthEstimatedProfitLabel,
                              value:
                                  'NPR ${currFmt.format(_toDouble(summary['profit_est']))}',
                              color:
                                  _toDouble(summary['profit_est']) >= 0
                                      ? AppColors.primary
                                      : AppColors.error,
                              icon: Icons.insights_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.businessHealthOutstandingCreditLabel,
                              value:
                                  'NPR ${currFmt.format(_toDouble(summary['outstanding_total']))}',
                              color: AppColors.warning,
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.businessHealthProfitMarginLabel,
                              value:
                                  '${_toDouble(summary['profit_margin']).toStringAsFixed(1)}%',
                              color: AppColors.primary,
                              icon: Icons.percent_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.businessHealthCashRiskLabel,
                              value:
                                  (summary['cash_risk_level']?.toString() ??
                                          'low')
                                      .toUpperCase(),
                              color: _cashRiskColor(
                                summary['cash_risk_level']?.toString(),
                              ),
                              icon: Icons.shield_outlined,
                            ),
                          ),
                        ],
                      ),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                reasons
                                    .map(
                                      (r) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          '• $r',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(l10n.businessHealthCashOutlookTitle),
            const SizedBox(height: AppSpacing.sm),
            businessAsync.when(
              loading: () => const SkeletonListTile(),
              error:
                  (_, __) => ErrorRetry(
                    onRetry: () => ref.invalidate(businessMetricsProvider),
                  ),
              data: (summary) {
                final incoming = _toDouble(summary['expected_incoming_soon']);
                final outgoing = _toDouble(summary['expected_outgoing_soon']);
                final net = _toDouble(summary['net_cash_outlook_soon']);
                final horizonDays = _toInt(summary['cash_horizon_days']);
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.businessHealthExpectedIncomingLabel,
                              value: 'NPR ${currFmt.format(incoming)}',
                              color: AppColors.success,
                              icon: Icons.south_west_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _HealthStatTile(
                              label: l10n.businessHealthExpectedOutgoingLabel,
                              value: 'NPR ${currFmt.format(outgoing)}',
                              color: AppColors.error,
                              icon: Icons.north_east_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color:
                              (net >= 0
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color:
                                (net >= 0
                                        ? AppColors.success
                                        : AppColors.error)
                                    .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              net >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 18,
                              color:
                                  net >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                l10n.businessHealthNetOutlookNextDays(
                                  horizonDays > 0 ? horizonDays : 7,
                                  currFmt.format(net),
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.businessHealthProfitSnapshotNote,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              l10n.businessHealthCreditRiskSummaryTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            riskAsync.when(
              loading: () => const SkeletonListTile(),
              error:
                  (_, __) => ErrorRetry(
                    onRetry:
                        () => ref.invalidate(
                          customerMetricsReportProvider(_riskParams),
                        ),
                  ),
              data:
                  (body) =>
                      _CreditRiskSummaryCard(body: body, currFmt: currFmt),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(l10n.businessHealthStockHealthTitle),
            const SizedBox(height: AppSpacing.sm),
            lowStockAsync.when(
              loading: () => const SkeletonListTile(),
              error:
                  (_, __) => ErrorRetry(
                    onRetry: () => ref.invalidate(lowStockProductsProvider),
                  ),
              data: (products) => _StockHealthCard(products: products),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(l10n.businessHealthFastMoversTitle),
            const SizedBox(height: AppSpacing.sm),
            productMetricsAsync.when(
              loading: () => const SkeletonListTile(),
              error:
                  (_, __) => ErrorRetry(
                    onRetry:
                        () => ref.invalidate(
                          productMetricsReportProvider(_productParams),
                        ),
                  ),
              data: (body) => _FastMoversCard(body: body),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(l10n.businessHealthAlertsPreviewTitle),
            const SizedBox(height: AppSpacing.sm),
            alertsAsync.when(
              loading: () => const SkeletonListTile(),
              error:
                  (_, __) => ErrorRetry(
                    onRetry: () => ref.invalidate(alertsFeedProvider),
                  ),
              data:
                  (alerts) =>
                      _AlertsPreviewCard(alerts: alerts.take(5).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CachedMetricsHintCard extends StatelessWidget {
  const _CachedMetricsHintCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

Color _cashRiskColor(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'high':
      return AppColors.error;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

class _HealthStatTile extends StatelessWidget {
  const _HealthStatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

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
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditRiskSummaryCard extends StatelessWidget {
  const _CreditRiskSummaryCard({required this.body, required this.currFmt});

  final Map<String, dynamic> body;
  final NumberFormat currFmt;

  @override
  Widget build(BuildContext context) {
    final items =
        (body['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final totalOutstanding = _toDouble(body['total_outstanding']);
    final totalOverdue = _toDouble(body['total_overdue']);
    final highRiskCount = _toInt(body['high_risk_count']);
    final topHighRisk =
        items
            .where(
              (i) => (i['risk_level']?.toString().toLowerCase() ?? '') == 'red',
            )
            .take(5)
            .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _RiskSummaryPill(
                  label: AppLocalizations.of(context)!.creditAgingOutstandingLabel,
                  value: 'NPR ${currFmt.format(totalOutstanding)}',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RiskSummaryPill(
                  label: AppLocalizations.of(context)!.creditAgingOverdueLabel,
                  value: 'NPR ${currFmt.format(totalOverdue)}',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.creditAgingHighRiskCustomersCount(
              highRiskCount,
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          if (topHighRisk.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...topHighRisk.map(
              (row) => _TapLine(
                title:
                    '${row['customer_name'] ?? AppLocalizations.of(context)!.customerLabel} • NPR ${currFmt.format(_toDouble(row['outstanding_amount']))}',
                subtitle:
                    '${AppLocalizations.of(context)!.creditAgingOldestDueLabel}: ${AppLocalizations.of(context)!.businessHealthDaysShort(_toInt(row['oldest_due_days']))}',
                color: AppColors.error,
                onTap:
                    row['customer_id'] == null
                        ? null
                        : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => CustomerDetailScreen(
                                  customerId: row['customer_id'].toString(),
                                ),
                          ),
                        ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockHealthCard extends StatelessWidget {
  const _StockHealthCard({required this.products});

  final List<dynamic> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return AppCard(
        child: Text(
          AppLocalizations.of(context)!.businessHealthNoLowStockAlerts,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      );
    }

    final preview = products.take(5).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.businessHealthLowStockItemsCount(
              products.length,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...preview.map(
            (p) => _TapLine(
              title: '${p.name} • ${p.stockQty.toStringAsFixed(0)} ${p.unit}',
              subtitle:
                  '${AppLocalizations.of(context)!.thresholdLabel}: ${p.lowStockThreshold.toStringAsFixed(0)}',
              color: AppColors.warning,
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: p.id),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsPreviewCard extends StatelessWidget {
  const _AlertsPreviewCard({required this.alerts});

  final List<dynamic> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return AppCard(
        child: Text(
          AppLocalizations.of(context)!.businessHealthNoActiveAlerts,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            alerts.map((a) {
              final color = switch ((a.severity as String).toLowerCase()) {
                'critical' => AppColors.error,
                'warn' => AppColors.warning,
                _ => AppColors.primary,
              };
              return _TapLine(
                title: a.title,
                subtitle: a.body,
                color: color,
                onTap:
                    AlertActionRouter.canHandle(a)
                        ? () => AlertActionRouter.open(context, a)
                        : null,
              );
            }).toList(),
      ),
    );
  }
}

class _FastMoversCard extends StatelessWidget {
  const _FastMoversCard({required this.body});

  final Map<String, dynamic> body;

  @override
  Widget build(BuildContext context) {
    final items =
        (body['items'] as List?)?.whereType<ProductMetricItem>().toList() ??
        const <ProductMetricItem>[];
    final fast =
        items.where((p) => p.qtySold7d > 0).toList()
          ..sort((a, b) => b.qtySold7d.compareTo(a.qtySold7d));

    if (fast.isEmpty) {
      return AppCard(
        child: Text(
          AppLocalizations.of(context)!.businessHealthNoFastMovers7d,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      );
    }

    return AppCard(
      child: Column(
        children:
            fast.take(5).map((p) {
              return _TapLine(
                title: '${p.productName} • ${p.qtySold7d.toStringAsFixed(0)}',
                subtitle:
                    '${AppLocalizations.of(context)!.businessHealthSevenDayQtySoldLabel} • ${AppLocalizations.of(context)!.revenueLabel}: NPR ${p.revenue30d.toStringAsFixed(2)}',
                color: AppColors.primary,
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => ProductDetailScreen(productId: p.productId),
                      ),
                    ),
              );
            }).toList(),
      ),
    );
  }
}

class _RiskSummaryPill extends StatelessWidget {
  const _RiskSummaryPill({
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
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TapLine extends StatelessWidget {
  const _TapLine({
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: child,
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
