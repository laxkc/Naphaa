import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/context_i18n.dart';
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
    final currFmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Product Insights', 'वस्तु अन्तर्दृष्टि')),
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
                    context.tr('Dead Stock Only', 'नचल्ने स्टक मात्र'),
                  ),
                  selected: _deadStockOnly,
                  onSelected: (v) => setState(() => _deadStockOnly = v),
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _deadStockOnly ? Colors.white : AppColors.label,
                    fontWeight:
                        _deadStockOnly ? FontWeight.w700 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color:
                        _deadStockOnly ? AppColors.primary : AppColors.border,
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
                    title: context.tr(
                      'No product metrics yet',
                      'अहिलेसम्म वस्तु मेट्रिक्स छैन',
                    ),
                    subtitle: context.tr(
                      'Create sales and sync to see product insights',
                      'वस्तु अन्तर्दृष्टि हेर्न बिक्री र सिङ्क गर्नुहोस्',
                    ),
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
                                context.tr(
                                  'Showing cached product insights (offline). Refresh when internet is available.',
                                  'क्यास गरिएको वस्तु अन्तर्दृष्टि देखाइँदैछ (अफलाइन)। इन्टरनेट आएपछि रिफ्रेस गर्नुहोस्।',
                                ),
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
                              label: context.tr(
                                'Dead Stock Items',
                                'नचल्ने स्टक',
                              ),
                              value: '$deadStockCount',
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _SummaryMini(
                              label: context.tr(
                                'Locked Value',
                                'अड्किएको मूल्य',
                              ),
                              value:
                                  'NPR ${currFmt.format(deadStockValueTotal)}',
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
                              context.tr(
                                'Profit is estimated using product cost price (sell price - cost price) x quantity sold. It does not subtract allocated business expenses. Products without cost price are excluded from profit ranking.',
                                'नाफा अनुमानित हो (बिक्री मूल्य - लागत मूल्य) x बिक्री मात्रा। यसमा व्यवसायिक खर्च बाँडेर घटाइएको छैन। लागत मूल्य नभएका वस्तु नाफा सूचीमा समावेश हुँदैनन्।',
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      context.tr('Top Profit Products', 'उच्च नाफा वस्तु'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children:
                            topProfit.take(5).map((p) {
                              return _MetricLine(
                                title: p.productName,
                                subtitle:
                                    '${context.tr('Profit', 'नाफा')}: NPR ${currFmt.format(p.profit30d ?? 0)} • ${context.tr('Revenue', 'आम्दानी')}: NPR ${currFmt.format(p.revenue30d)}',
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
                      context.tr(
                        'Fast Movers (7d)',
                        'छिटो बिक्ने वस्तु (७ दिन)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children:
                            fastMovers.take(5).map((p) {
                              return _MetricLine(
                                title: p.productName,
                                subtitle:
                                    '${context.tr('Qty sold (7d)', '७ दिनको बिक्री मात्रा')}: ${p.qtySold7d.toStringAsFixed(0)} • ${context.tr('Revenue', 'आम्दानी')}: NPR ${currFmt.format(p.revenue30d)}',
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
                    SectionHeader(context.tr('Dead Stock', 'नचल्ने स्टक')),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        children:
                            items.where((i) => i.deadStock).take(20).map((p) {
                              final lastSale =
                                  p.lastSaleAt == null
                                      ? context.tr(
                                        'No sales yet',
                                        'अहिलेसम्म बिक्री छैन',
                                      )
                                      : '${context.tr('Last sale', 'अन्तिम बिक्री')}: ${dateFmt.format(p.lastSaleAt!.toLocal())}';
                              final deadValue =
                                  p.deadStockValue == null
                                      ? context.tr(
                                        'Cost not set',
                                        'लागत सेट छैन',
                                      )
                                      : 'NPR ${currFmt.format(p.deadStockValue)}';
                              return _MetricLine(
                                title:
                                    '${p.productName} • ${p.stockQty.toStringAsFixed(0)}',
                                subtitle:
                                    '$lastSale • ${context.tr('Value', 'मूल्य')}: $deadValue',
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
