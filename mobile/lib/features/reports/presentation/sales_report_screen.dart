import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  _Period _period = _Period.today;
  final _currFmt = NumberFormat('#,##0.00');

  ReportParams get _params {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    return switch (_period) {
      _Period.today => ReportParams(
          fromDate: todayStart,
          toDate: tomorrowStart,
        ),
      _Period.week => ReportParams(
          fromDate: todayStart.subtract(Duration(days: now.weekday - 1)),
          toDate: tomorrowStart,
        ),
      _Period.month => ReportParams(
          fromDate: DateTime(now.year, now.month, 1),
          toDate: tomorrowStart,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final params = _params;
    final reportAsync = ref.watch(salesReportProvider(params));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.reportsSalesReportTitle),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: _Period.values.map((p) {
                final selected = _period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(_periodLabel(p)),
                    selected: selected,
                    onSelected: (_) => setState(() => _period = p),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.label,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                  onRetry: () =>
                      ref.invalidate(salesReportProvider(params))),
              data: (report) {
                final totalRevenue =
                    (report['total_revenue'] as num).toDouble();
                final totalOrders =
                    report['total_transactions'] as int? ?? 0;
                final cashRevenue =
                    (report['cash_total'] as num? ?? 0).toDouble();
                final creditRevenue =
                    (report['credit_total'] as num? ?? 0).toDouble();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Total revenue card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.salesReportTotalRevenue,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              'NPR ${_currFmt.format(totalRevenue)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.salesReportTransactionCount(totalOrders),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(l10n.salesReportBreakdownByType),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _BreakdownRow(
                              label: l10n.salesReportCashSales,
                              amount: cashRevenue,
                              total: totalRevenue,
                              color: AppColors.success,
                              currFmt: _currFmt,
                            ),
                            const Divider(height: 1),
                            _BreakdownRow(
                              label: l10n.salesReportCreditSales,
                              amount: creditRevenue,
                              total: totalRevenue,
                              color: AppColors.warning,
                              currFmt: _currFmt,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(_Period p) => switch (p) {
        _Period.today => AppLocalizations.of(context)!.todayLabel,
        _Period.week => AppLocalizations.of(context)!.thisWeekLabel,
        _Period.month => AppLocalizations.of(context)!.thisMonthLabel,
      };
}

enum _Period { today, week, month }

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
    required this.currFmt,
  });
  final String label;
  final double amount;
  final double total;
  final Color color;
  final NumberFormat currFmt;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text('NPR ${currFmt.format(amount)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${pct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
