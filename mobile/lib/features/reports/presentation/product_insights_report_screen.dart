import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/date/calendar_adapter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../domain/product_metric_item.dart';

class ProductInsightsReportScreen extends ConsumerStatefulWidget {
  const ProductInsightsReportScreen({super.key});

  @override
  ConsumerState<ProductInsightsReportScreen> createState() =>
      _ProductInsightsReportScreenState();
}

class _ProductInsightsReportScreenState
    extends ConsumerState<ProductInsightsReportScreen> {
  bool _deadStockOnly = false;

  ProductMetricsQueryParams get _params => ProductMetricsQueryParams(
    deadStockOnly: _deadStockOnly,
    limit: 500,
    windowDays: 30,
    deadStockDays: 30,
  );

  @override
  Widget build(BuildContext context) {
    final params = _params;
    final reportAsync = ref.watch(productMetricsReportProvider(params));
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final calendarAsync = ref.watch(calendarAdapterProvider);
    final calendar =
        calendarAsync is AsyncData<CalendarAdapter>
            ? calendarAsync.value
            : CalendarAdapter(calendarMode: 'AD', localeCode: localeCode);
    final currFmt = NumberFormat('#,##0.00');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.reportsProductInsightsTitle),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    l10n.productInsightsDeadStockOnly,
                  ),
                  selected: _deadStockOnly,
                  onSelected: (v) => setState(() => _deadStockOnly = v),
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: _deadStockOnly ? Colors.white : AppColors.label,
                    fontWeight:
                        _deadStockOnly ? FontWeight.w700 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _deadStockOnly ? AppColors.accent : AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              loading:
                  () => ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 6,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, __) => const SkeletonListTile(),
                  ),
              error:
                  (e, _) => ErrorRetry(
                    onRetry:
                        () => ref.invalidate(
                          productMetricsReportProvider(params),
                        ),
                  ),
              data: (body) {
                final items =
                    (body['items'] as List?)
                        ?.whereType<ProductMetricItem>()
                        .toList() ??
                    const <ProductMetricItem>[];
                final deadStockCount = _toInt(body['dead_stock_count']);
                final deadStockValueTotal = _toDouble(
                  body['dead_stock_value_total'],
                );
                final fastMovers =
                    items.where((i) => i.qtySold7d > 0).toList()
                      ..sort((a, b) => b.qtySold7d.compareTo(a.qtySold7d));
                final topProfit =
                    items.where((i) => i.profit30d != null).toList()..sort(
                      (a, b) => (b.profit30d ?? 0).compareTo(a.profit30d ?? 0),
                    );

                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.productInsightsNoDataTitle,
                    subtitle: l10n.productInsightsNoDataSubtitle,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (body['source']?.toString() == 'local_cache') ...[
                      AppCard(
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
                                l10n.productInsightsCachedDataBanner,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryMini(
                              label: l10n.productInsightsDeadStockItemsLabel,
                              value: '$deadStockCount',
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _SummaryMini(
                              label: l10n.productInsightsLockedValueLabel,
                              value:
                                  '${l10n.nprLabel} ${currFmt.format(deadStockValueTotal)}',
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
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
                              l10n.productInsightsProfitNote,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      l10n.productInsightsTopProfitProductsTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children:
                            topProfit.take(5).map((p) {
                              return _MetricLine(
                                title: p.productName,
                                subtitle:
                                    '${l10n.productInsightsProfitLabel}: ${l10n.nprLabel} ${currFmt.format(p.profit30d ?? 0)} • ${l10n.revenueLabel}: ${l10n.nprLabel} ${currFmt.format(p.revenue30d)}',
                                color: AppColors.success,
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ProductDetailScreen(
                                              productId: p.productId,
                                            ),
                                      ),
                                    ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      l10n.productInsightsFastMovers7dTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children:
                            fastMovers.take(5).map((p) {
                              return _MetricLine(
                                title: p.productName,
                                subtitle:
                                    '${l10n.productInsightsQtySold7dLabel}: ${p.qtySold7d.toStringAsFixed(0)} • ${l10n.revenueLabel}: ${l10n.nprLabel} ${currFmt.format(p.revenue30d)}',
                                color: AppColors.primary,
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ProductDetailScreen(
                                              productId: p.productId,
                                            ),
                                      ),
                                    ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.productInsightsDeadStockTitle),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children:
                            items.where((i) => i.deadStock).take(20).map((p) {
                              final lastSale =
                                  p.lastSaleAt == null
                                      ? l10n.productInsightsNoSalesYet
                                      : '${l10n.productInsightsLastSaleLabel}: ${calendar.formatBusinessDate(p.lastSaleAt!.toLocal())}';
                              final deadValue =
                                  p.deadStockValue == null
                                      ? l10n.productInsightsCostNotSet
                                      : '${l10n.nprLabel} ${currFmt.format(p.deadStockValue)}';
                              return _MetricLine(
                                title:
                                    '${p.productName} • ${p.stockQty.toStringAsFixed(0)}',
                                subtitle:
                                    '$lastSale • ${l10n.productInsightsValueLabel}: $deadValue',
                                color: AppColors.warning,
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ProductDetailScreen(
                                              productId: p.productId,
                                            ),
                                      ),
                                    ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMini extends StatelessWidget {
  const _SummaryMini({
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
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
    final row = Padding(
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
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: row,
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
