import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import 'package:sme_digital/core/l10n/display_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/date/business_clock.dart';
import '../../../core/date/calendar_adapter.dart';
import '../../../core/date/business_time.dart';
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
  final _timeFmt = DateFormat('h:mm a');
  final _currFmt = NumberFormat('#,##0.00');

  SalesListParams _queryParams(BusinessClock clock) {
    final todayRange = clock.todayRange();
    switch (_filter) {
      case _DateFilter.today:
        return SalesListParams(
          fromDate: todayRange.fromDate,
          toDate: todayRange.toDate,
        );
      case _DateFilter.week:
        final range = clock.currentWeekRange();
        return SalesListParams(fromDate: range.fromDate, toDate: range.toDate);
      case _DateFilter.month:
        final range = clock.currentMonthRange();
        return SalesListParams(fromDate: range.fromDate, toDate: range.toDate);
      case _DateFilter.all:
        return const SalesListParams();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final clockAsync = ref.watch(businessClockProvider);
    final clock =
        clockAsync is AsyncData<BusinessClock>
            ? clockAsync.value
            : BusinessClock.fallback();
    final queryParams = _queryParams(clock);
    final salesAsync = ref.watch(salesListProvider(queryParams));
    final calendarAsync = ref.watch(calendarAdapterProvider);
    final calendar =
        calendarAsync is AsyncData<CalendarAdapter>
            ? calendarAsync.value
            : CalendarAdapter(calendarMode: 'AD', localeCode: localeCode);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      appBar:
          widget.standalone
              ? AppBar(
                title: Text(l10n.sales),
                backgroundColor: AppColors.surface,
              )
              : null,
      body: SafeArea(
        top: false,
        child: Column(
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
                            selectedColor: AppColors.accent,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.label,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                            ),
                            side: BorderSide(
                              color:
                                  selected
                                      ? AppColors.accent
                                      : AppColors.border,
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
                            calendar: calendar,
                            timeFmt: _timeFmt,
                            currFmt: _currFmt,
                            onTap:
                                () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SaleDetailScreen(
                                          saleId: sales[i].id,
                                        ),
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
    required this.calendar,
    required this.timeFmt,
    required this.currFmt,
    required this.onTap,
  });
  final Sale sale;
  final CalendarAdapter calendar;
  final DateFormat timeFmt;
  final NumberFormat currFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final method = sale.paymentMethod.toUpperCase();
    final isCash = method == 'CASH';
    final isCredit = method == 'CREDIT';
    final methodIcon = switch (method) {
      'CASH' => Icons.payments_outlined,
      'QR' => Icons.qr_code_outlined,
      'BANK' => Icons.account_balance_outlined,
      'WALLET' => Icons.account_balance_wallet_outlined,
      'CREDIT' => Icons.credit_card_outlined,
      'MIXED' => Icons.call_split_outlined,
      _ => Icons.attach_money,
    };

    final saleDate = _displayDate();
    final saleTime = timeFmt.format(sale.createdAt.toLocal());

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
              methodIcon,
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
                  sale.customerName ?? l10n.walkInCustomer,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$saleDate • $saleTime',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${l10n.nprLabel} ${currFmt.format(sale.totalAmount)}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.label),
              ),
              const SizedBox(height: 4),
              StatusChip(
                label: paymentMethodLabel(context, sale.paymentMethod),
                color: isCash ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(height: 4),
              StatusChip(
                label: saleStatusLabel(context, sale.status.name),
                color: _statusColor(sale.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayDate() {
    final adDate = BusinessTime.parseAdDate(sale.saleDateAd ?? '');
    if (adDate != null) {
      return calendar.formatBusinessDate(adDate);
    }
    final derivedAd = BusinessTime.parseAdDate(
      BusinessTime.businessDateAd(timestampUtc: sale.createdAt.toUtc()),
    );
    return calendar.formatBusinessDate(derivedAd ?? sale.createdAt.toLocal());
  }

  Color _statusColor(SaleStatus status) => switch (status) {
    SaleStatus.completed => AppColors.success,
    SaleStatus.partial => AppColors.warning,
    SaleStatus.refunded => AppColors.muted,
    SaleStatus.voided => AppColors.error,
  };
}
