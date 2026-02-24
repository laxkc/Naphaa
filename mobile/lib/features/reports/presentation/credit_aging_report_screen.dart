import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../customers/presentation/customer_detail_screen.dart';

class CreditAgingReportScreen extends ConsumerStatefulWidget {
  const CreditAgingReportScreen({super.key});

  @override
  ConsumerState<CreditAgingReportScreen> createState() =>
      _CreditAgingReportScreenState();
}

class _CreditAgingReportScreenState
    extends ConsumerState<CreditAgingReportScreen> {
  bool _overdueOnly = false;
  bool _highRiskOnly = false;
  final _currFmt = NumberFormat('#,##0.00');

  CustomerMetricsQueryParams get _params => CustomerMetricsQueryParams(
    overdueOnly: _overdueOnly,
    highRiskOnly: _highRiskOnly,
    limit: 500,
  );

  @override
  Widget build(BuildContext context) {
    final params = _params;
    final reportAsync = ref.watch(customerMetricsReportProvider(params));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Credit Aging', 'उधारो उमेर रिपोर्ट')),
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
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                FilterChip(
                  label: Text(context.tr('Overdue Only', 'समय नाघेको मात्र')),
                  selected: _overdueOnly,
                  onSelected: (v) => setState(() => _overdueOnly = v),
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _overdueOnly ? Colors.white : AppColors.label,
                    fontWeight:
                        _overdueOnly ? FontWeight.w700 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _overdueOnly ? AppColors.primary : AppColors.border,
                  ),
                ),
                FilterChip(
                  label: Text(context.tr('High Risk Only', 'उच्च जोखिम मात्र')),
                  selected: _highRiskOnly,
                  onSelected: (v) => setState(() => _highRiskOnly = v),
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _highRiskOnly ? Colors.white : AppColors.label,
                    fontWeight:
                        _highRiskOnly ? FontWeight.w700 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _highRiskOnly ? AppColors.primary : AppColors.border,
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => const SkeletonListTile(),
                  ),
              error:
                  (e, _) => ErrorRetry(
                    onRetry:
                        () => ref.invalidate(
                          customerMetricsReportProvider(params),
                        ),
                  ),
              data: (body) => _buildContent(context, body),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> body) {
    final totals = _asMap(body['totals']);
    final items =
        (body['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final totalOutstanding = _toDouble(body['total_outstanding']);
    final totalOverdue = _toDouble(body['total_overdue']);
    final highRiskCount = _toInt(body['high_risk_count']);

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.query_stats_rounded,
        title: context.tr('No credit aging data', 'उधारो उमेर डेटा छैन'),
        subtitle: context.tr(
          'No customers match the selected filters',
          'छनोट गरिएका फिल्टरमा कुनै ग्राहक छैन',
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
                      'Showing cached credit aging data (offline). Refresh when internet is available.',
                      'क्यास गरिएको उधारो उमेर डेटा देखाइँदैछ (अफलाइन)। इन्टरनेट आएपछि रिफ्रेस गर्नुहोस्।',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Credit Aging Summary', 'उधारो उमेर सारांश'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: context.tr('Outstanding', 'कुल बाँकी'),
                      value: 'NPR ${_currFmt.format(totalOutstanding)}',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SummaryStat(
                      label: context.tr('Overdue', 'समय नाघेको'),
                      value: 'NPR ${_currFmt.format(totalOverdue)}',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(
                  '$highRiskCount high-risk customer${highRiskCount == 1 ? '' : 's'}',
                  '$highRiskCount उच्च जोखिम ग्राहक',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(context.tr('Aging Buckets', 'उमेर समूह')),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _BucketRow(
                label: '0–7 ${context.tr('days', 'दिन')}',
                amount: _toDouble(totals['d0_7']),
                color: AppColors.success,
                fmt: _currFmt,
              ),
              const Divider(height: 1),
              _BucketRow(
                label: '8–30 ${context.tr('days', 'दिन')}',
                amount: _toDouble(totals['d8_30']),
                color: AppColors.warning,
                fmt: _currFmt,
              ),
              const Divider(height: 1),
              _BucketRow(
                label: '31–60 ${context.tr('days', 'दिन')}',
                amount: _toDouble(totals['d31_60']),
                color: const Color(0xFFE67E22),
                fmt: _currFmt,
              ),
              const Divider(height: 1),
              _BucketRow(
                label: '60+ ${context.tr('days', 'दिन')}',
                amount: _toDouble(totals['d60_plus']),
                color: AppColors.error,
                fmt: _currFmt,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(context.tr('Customers', 'ग्राहकहरू')),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CustomerAgingCard(item: item, currFmt: _currFmt),
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.label,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.fmt,
  });

  final String label;
  final double amount;
  final Color color;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            'NPR ${fmt.format(amount)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAgingCard extends StatelessWidget {
  const _CustomerAgingCard({required this.item, required this.currFmt});

  final Map<String, dynamic> item;
  final NumberFormat currFmt;

  @override
  Widget build(BuildContext context) {
    final customerId = item['customer_id']?.toString() ?? '';
    final name = item['customer_name']?.toString() ?? 'Unknown';
    final phone = item['phone']?.toString();
    final riskLevel = (item['risk_level']?.toString() ?? 'green').toLowerCase();
    final riskScore = _toInt(item['risk_score']);
    final oldestDueDays = _toInt(item['oldest_due_days']);
    final outstandingAmount = _toDouble(item['outstanding_amount']);
    final aging = _asMap(item['aging']);
    final (riskLabel, riskColor) = switch (riskLevel) {
      'red' => ('High', AppColors.error),
      'yellow' => ('Medium', AppColors.warning),
      _ => ('Low', AppColors.success),
    };

    return AppCard(
      onTap:
          customerId.isEmpty
              ? null
              : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerDetailScreen(customerId: customerId),
                ),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone != null && phone.isNotEmpty)
                      Text(
                        phone,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: riskColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$riskLabel • $riskScore',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Outstanding', 'बाँकी'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
              Text(
                'NPR ${currFmt.format(outstandingAmount)}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Oldest Due', 'सबैभन्दा पुरानो बाँकी'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
              Text(
                '$oldestDueDays ${context.tr('days', 'दिन')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      oldestDueDays > 30
                          ? AppColors.error
                          : oldestDueDays > 7
                          ? AppColors.warning
                          : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _AgingChip(
                label: '0–7',
                amount: _toDouble(aging['d0_7']),
                color: AppColors.success,
                fmt: currFmt,
              ),
              _AgingChip(
                label: '8–30',
                amount: _toDouble(aging['d8_30']),
                color: AppColors.warning,
                fmt: currFmt,
              ),
              _AgingChip(
                label: '31–60',
                amount: _toDouble(aging['d31_60']),
                color: const Color(0xFFE67E22),
                fmt: currFmt,
              ),
              _AgingChip(
                label: '60+',
                amount: _toDouble(aging['d60_plus']),
                color: AppColors.error,
                fmt: currFmt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgingChip extends StatelessWidget {
  const _AgingChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.fmt,
  });

  final String label;
  final double amount;
  final Color color;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.label,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: fmt.format(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
