import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/sale.dart';
import 'create_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  _DateFilter _filter = _DateFilter.today;
  final _fmt = DateFormat('MMM d, h:mm a');
  final _currFmt = NumberFormat('#,##0.00');

  SalesListParams get _queryParams {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    switch (_filter) {
      case _DateFilter.today:
        return SalesListParams(fromDate: todayStart, toDate: tomorrowStart);
      case _DateFilter.week:
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return SalesListParams(fromDate: weekStart, toDate: tomorrowStart);
      case _DateFilter.month:
        return SalesListParams(
          fromDate: DateTime(now.year, now.month, 1),
          toDate: tomorrowStart,
        );
      case _DateFilter.all:
        return const SalesListParams();
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryParams = _queryParams;
    final salesAsync = ref.watch(salesListProvider(queryParams));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar:
          widget.standalone
              ? AppBar(
                title: Text(l10n.sales),
                backgroundColor: AppColors.surface,
              )
              : null,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _DateFilter.values.map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(_filterLabel(f)),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          showCheckmark: false,
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.label,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                          ),
                          side: BorderSide(
                            color:
                                selected ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: salesAsync.when(
              loading:
                  () => ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 8,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, __) => const SkeletonListTile(),
                  ),
              error:
                  (e, _) => ErrorRetry(
                    onRetry:
                        () => ref.invalidate(salesListProvider(queryParams)),
                  ),
              data: (sales) {
                if (sales.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.salesNoSalesYetTitle,
                    subtitle:
                        _filter == _DateFilter.today
                            ? l10n.salesNoSalesYetTodaySubtitle
                            : l10n.salesNoTransactionsInPeriodSubtitle,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh:
                      () async =>
                          ref.invalidate(salesListProvider(queryParams)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: sales.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder:
                        (_, i) => _SaleTile(
                          sale: sales[i],
                          fmt: _fmt,
                          currFmt: _currFmt,
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          SaleDetailScreen(saleId: sales[i].id),
                                ),
                              ),
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.newSale),
        onPressed:
            () => Navigator.of(context)
                .push(
                  MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
                )
                .then((_) => ref.invalidate(salesListProvider(queryParams))),
      ),
    );
  }

  String _filterLabel(_DateFilter f) => switch (f) {
    _DateFilter.today => AppLocalizations.of(context)!.todayLabel,
    _DateFilter.week => AppLocalizations.of(context)!.thisWeekLabel,
    _DateFilter.month => AppLocalizations.of(context)!.thisMonthLabel,
    _DateFilter.all => AppLocalizations.of(context)!.allLabel,
  };
}

enum _DateFilter { today, week, month, all }

class _SaleTile extends StatelessWidget {
  const _SaleTile({
    required this.sale,
    required this.fmt,
    required this.currFmt,
    required this.onTap,
  });
  final Sale sale;
  final DateFormat fmt;
  final NumberFormat currFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCash = sale.saleType == 'CASH';
    final isCredit = sale.saleType == 'CREDIT';

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  isCash
                      ? AppColors.successBg
                      : isCredit
                      ? AppColors.warningBg
                      : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isCash
                  ? Icons.payments_outlined
                  : isCredit
                  ? Icons.credit_card_outlined
                  : Icons.call_split_outlined,
              size: 20,
              color:
                  isCash
                      ? AppColors.success
                      : isCredit
                      ? AppColors.warning
                      : AppColors.muted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName ??
                      l10n.walkInCustomer,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.format(sale.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'NPR ${currFmt.format(sale.totalAmount)}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.label),
              ),
              const SizedBox(height: 4),
              StatusChip(
                label: sale.saleType,
                color: isCash ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
