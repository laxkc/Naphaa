import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';

class ProfitReportScreen extends ConsumerStatefulWidget {
  const ProfitReportScreen({super.key});

  @override
  ConsumerState<ProfitReportScreen> createState() =>
      _ProfitReportScreenState();
}

class _ProfitReportScreenState extends ConsumerState<ProfitReportScreen> {
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
    final expensesAsync = ref.watch(expensesListProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.reportsProfitReportTitle),
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
                  onRetry: () {
                    ref.invalidate(salesReportProvider(params));
                    ref.invalidate(expensesListProvider);
                  }),
              data: (report) {
                final revenue =
                    (report['total_revenue'] as num).toDouble();
                final localFrom = params.fromDate.toLocal();
                final localTo = params.toDate.toLocal();
                final expenses = expensesAsync.when(
                  loading: () => 0.0,
                  error: (_, __) => 0.0,
                  data: (items) => items
                      .where((e) {
                        final createdAt = e.createdAt.toLocal();
                        if (createdAt.isBefore(localFrom)) {
                          return false;
                        }
                        if (createdAt.isAfter(localTo)) {
                          return false;
                        }
                        return true;
                      })
                      .fold<double>(0.0, (sum, e) => sum + e.amount),
                );
                final grossProfit = revenue * 0.3;
                final netProfit = grossProfit - expenses;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.profitReportNetProfit,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              'NPR ${_currFmt.format(netProfit)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: netProfit >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(l10n.profitReportBreakdown),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ProfitRow(
                              label: l10n.salesReportTotalRevenue,
                              value: revenue,
                              color: AppColors.primary,
                              currFmt: _currFmt,
                            ),
                            const Divider(height: 1),
                            _ProfitRow(
                              label: l10n.profitReportEstimatedGrossProfit30,
                              value: grossProfit,
                              color: AppColors.success,
                              currFmt: _currFmt,
                            ),
                            const Divider(height: 1),
                            _ProfitRow(
                              label: l10n.profitReportTotalExpenses,
                              value: -expenses,
                              color: AppColors.error,
                              currFmt: _currFmt,
                            ),
                            const Divider(height: 1),
                            _ProfitRow(
                              label: l10n.profitReportNetProfit,
                              value: netProfit,
                              color: netProfit >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              currFmt: _currFmt,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InlineBanner(
                        type: BannerType.info,
                        message:
                            l10n.profitReportEstimatedNotice,
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

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({
    required this.label,
    required this.value,
    required this.color,
    required this.currFmt,
    this.isBold = false,
  });
  final String label;
  final double value;
  final Color color;
  final NumberFormat currFmt;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isBold ? FontWeight.w700 : FontWeight.w400,
                    )),
          ),
          Text(
            '${value < 0 ? '-' : ''}NPR ${currFmt.format(value.abs())}',
            style: TextStyle(
              fontSize: isBold ? 15 : 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
