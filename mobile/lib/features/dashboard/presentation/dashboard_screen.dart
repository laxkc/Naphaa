import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/date/business_clock.dart';
import '../../../core/date/calendar_adapter.dart';
import '../../../core/utils/formatters.dart';
import '../../customers/presentation/customer_form_screen.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_form_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../reports/presentation/credit_report_screen.dart';
import '../../reports/presentation/credit_aging_report_screen.dart';
import '../../reports/presentation/business_health_screen.dart';
import '../../reports/presentation/alerts_feed_screen.dart';
import '../../reports/domain/alert_item.dart';
import '../../billing/presentation/invoice_list_screen.dart';
import '../../sales/presentation/create_sale_screen.dart';
import '../../sales/presentation/sales_list_screen.dart';
import '../../../shared/widgets/ui_kit.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final lowStock = ref.watch(lowStockProductsProvider);
    final alerts = ref.watch(alertsUnreadFeedProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return summary.when(
      loading: () => const _DashboardSkeleton(),
      error:
          (_, __) => ErrorRetry(
            onRetry: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(lowStockProductsProvider);
              ref.invalidate(productsListProvider);
            },
            message: l10n.failedToLoadDashboard,
          ),
      data: (data) {
        final sales = data.todaySales;
        final expenses = data.todayExpenses;
        final profit = data.estimatedProfit;
        final credit = data.creditOutstanding;
        final creditRatio =
            sales <= 0
                ? (credit > 0 ? 1.0 : 0.0)
                : (credit / sales).clamp(0.0, 1.0);
        final status = _healthStatus(l10n, profit, creditRatio);
        final clockAsync = ref.watch(businessClockProvider);
        final clock =
            clockAsync is AsyncData<BusinessClock>
                ? clockAsync.value
                : BusinessClock.fallback();
        final calendarAsync = ref.watch(calendarAdapterProvider);
        final calendar =
            calendarAsync is AsyncData<CalendarAdapter>
                ? calendarAsync.value
                : CalendarAdapter(
                  calendarMode: 'AD',
                  localeCode: localeCode,
                );
        final today = calendar.formatBusinessDate(clock.currentBusinessDate());

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(productsListProvider);
            ref.invalidate(lowStockProductsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardTopRow(alerts: alerts, l10n: l10n),
                const SizedBox(height: AppSpacing.sm),

                // ── hero card ──────────────────────────────────────────────
                _HeroCard(
                  sales: sales,
                  expenses: expenses,
                  profit: profit,
                  localeCode: localeCode,
                  today: today,
                  l10n: l10n,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── quick actions ──────────────────────────────────────────
                const _QuickActions(),
                const SizedBox(height: AppSpacing.md),

                // ── cashflow health card ───────────────────────────────────
                _HealthCard(
                  l10n: l10n,
                  credit: credit,
                  creditRatio: creditRatio,
                  status: status,
                  localeCode: localeCode,
                ),
                const SizedBox(height: AppSpacing.md),
                _LowStockCard(lowStock: lowStock),
              ],
            ),
          ),
        );
      },
    );
  }

  _HealthStatus _healthStatus(
    AppLocalizations l10n,
    double profit,
    double creditRatio,
  ) {
    if (profit >= 0 && creditRatio < 0.4) {
      return _HealthStatus(l10n.healthy, AppColors.success);
    }
    if (profit >= 0 && creditRatio < 0.8) {
      return _HealthStatus(l10n.watchlist, AppColors.warning);
    }
    return _HealthStatus(l10n.risky, AppColors.error);
  }
}

class _DashboardTopRow extends StatelessWidget {
  const _DashboardTopRow({required this.alerts, required this.l10n});

  final AsyncValue<List<AlertItem>> alerts;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (count, bellColor, badgeColor, icon, statusLabel) = alerts.when(
      loading:
          () => (
            0,
            AppColors.muted,
            AppColors.muted,
            Icons.notifications_outlined,
            l10n.loadingLabel,
          ),
      error:
          (_, __) => (
            0,
            AppColors.warning,
            AppColors.warning,
            Icons.notifications_active_outlined,
            l10n.errorLabel,
          ),
      data: (items) {
        final critical =
            items.where((a) => a.severity.toLowerCase() == 'critical').length;
        final warn =
            items.where((a) => a.severity.toLowerCase() == 'warn').length;
        final count = items.length;
        if (critical > 0) {
          return (
            count,
            AppColors.error,
            AppColors.error,
            Icons.notifications_active_rounded,
            l10n.criticalLabel,
          );
        }
        if (warn > 0) {
          return (
            count,
            AppColors.warning,
            AppColors.warning,
            Icons.notifications_active_outlined,
            l10n.warningLabel,
          );
        }
        return (
          count,
          AppColors.label,
          AppColors.success,
          Icons.notifications_none_rounded,
          l10n.clearLabel,
        );
      },
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboard,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (count > 0)
                Text(
                  l10n.alertCount(count),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label:
              count > 0
                  ? l10n.alertsCountWithStatus(count, statusLabel)
                  : l10n.alertsLabel,
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlertsFeedScreen()),
                );
              },
              child: Tooltip(
                message:
                    count > 0
                        ? l10n.alertsCountWithStatus(count, statusLabel)
                        : l10n.alertsLabel,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(icon, color: bellColor, size: 22),
                        if (count > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              height: 16,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.sales,
    required this.expenses,
    required this.profit,
    required this.localeCode,
    required this.today,
    required this.l10n,
  });

  final double sales;
  final double expenses;
  final double profit;
  final String localeCode;
  final String today;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final profitColor = profit >= 0 ? AppColors.successBg : AppColors.errorBg;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Stack(
        children: [
          // gradient background — Positioned.fill so it always covers full height
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
            ),
          ),
          // decorative circles
          Positioned(
            top: -28,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.13),
                
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top row: label + date chip
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bar_chart_rounded,
                            size: 16,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              l10n.dashboardOverview.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 82),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          today,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // sales amount
                Text(
                  formatCurrency(sales, localeCode),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 13,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.todaySales,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // thin divider
                Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(height: AppSpacing.md),
                // sub-stats row
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        icon: Icons.receipt_long_outlined,
                        label: l10n.expenses,
                        value: formatCurrency(expenses, localeCode),
                        valueColor: Colors.white,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    Expanded(
                      child: _HeroStat(
                        icon:
                            profit >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                        label: l10n.netAfterExpenses,
                        value: formatCurrency(profit, localeCode),
                        valueColor: profitColor,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final alignment =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? AppSpacing.md : 0,
        right: alignEnd ? 0 : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 12, color: Colors.white60),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── health card ──────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.l10n,
    required this.credit,
    required this.creditRatio,
    required this.status,
    required this.localeCode,
  });

  final AppLocalizations l10n;
  final double credit;
  final double creditRatio;
  final _HealthStatus status;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.cashflowHealth,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // progress
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: creditRatio,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              color: status.color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.creditOutstanding,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(credit, localeCode),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.label,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.creditExposure,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(creditRatio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: status.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── skeleton ─────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SkeletonBox(height: 170, radius: AppRadius.xl),
          const SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 130, radius: AppRadius.lg),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.lowStock});

  final AsyncValue<List<Product>> lowStock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.lowStockItemsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          lowStock.when(
            loading:
                () => Text(
                  l10n.checkingStock,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
            error:
                (_, __) => Text(
                  l10n.unableLoadLowStockData,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  l10n.allProductsAboveThreshold,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                );
              }
              final top = items.take(4).toList();
              return Column(
                children: [
                  for (final p in top)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warning,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p.name.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.label,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              l10n.stockLeftCount(p.stockQty.toStringAsFixed(0)),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HealthStatus {
  const _HealthStatus(this.label, this.color);
  final String label;
  final Color color;
}

// ─── quick actions ────────────────────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  void _pushAfterFrame(BuildContext context, Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    });
  }

  void _showSheetAfterFrame(BuildContext context, Widget child) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showAppBottomSheet(context, child: child);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActionsTitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final actions = <_QuickActionItem>[
              _QuickActionItem(
                icon: Icons.receipt_outlined,
                label: l10n.newSale,
                color: AppColors.primary,
                onTap: () => _pushAfterFrame(context, const CreateSaleScreen()),
              ),
              _QuickActionItem(
                icon: Icons.payments_outlined,
                label: l10n.recordPay,
                color: AppColors.warning,
                onTap:
                    () => _pushAfterFrame(context, const CreditReportScreen()),
              ),
              _QuickActionItem(
                icon: Icons.request_page_outlined,
                label: l10n.expenses,
                color: AppColors.error,
                onTap:
                    () => _showSheetAfterFrame(
                      context,
                      ExpenseFormSheet(ref: ref, l10n: l10n),
                    ),
              ),
              _QuickActionItem(
                icon: Icons.history_rounded,
                label: l10n.sales,
                color: AppColors.primaryLight,
                onTap:
                    () => _pushAfterFrame(
                      context,
                      const SalesListScreen(standalone: true),
                    ),
              ),
              _QuickActionItem(
                icon: Icons.group_outlined,
                label: l10n.customers,
                color: AppColors.primary,
                onTap:
                    () => _pushAfterFrame(
                      context,
                      const CustomersScreen(standalone: true),
                    ),
              ),
              _QuickActionItem(
                icon: Icons.inventory_2_outlined,
                label: l10n.products,
                color: AppColors.success,
                onTap:
                    () => _pushAfterFrame(
                      context,
                      const ProductsScreen(standalone: true),
                    ),
              ),
              _QuickActionItem(
                icon: Icons.person_add_outlined,
                label: l10n.addCustomer,
                color: AppColors.primaryLight,
                onTap:
                    () => _pushAfterFrame(context, const CustomerFormScreen()),
              ),
              _QuickActionItem(
                icon: Icons.receipt_long_outlined,
                label: l10n.invoices,
                color: AppColors.primary,
                onTap:
                    () => _pushAfterFrame(context, const InvoiceListScreen()),
              ),
              _QuickActionItem(
                icon: Icons.health_and_safety_outlined,
                label: l10n.businessHealth,
                color: AppColors.success,
                onTap:
                    () =>
                        _pushAfterFrame(context, const BusinessHealthScreen()),
              ),
              _QuickActionItem(
                icon: Icons.schedule_outlined,
                label: l10n.creditAging,
                color: AppColors.warning,
                onTap:
                    () => _pushAfterFrame(
                      context,
                      const CreditAgingReportScreen(),
                    ),
              ),
              _QuickActionItem(
                icon: Icons.notification_important_outlined,
                label: l10n.alertsLabel,
                color: AppColors.error,
                onTap: () => _pushAfterFrame(context, const AlertsFeedScreen()),
              ),
              _QuickActionItem(
                icon: Icons.add_box_outlined,
                label: l10n.addProduct,
                color: AppColors.success,
                onTap:
                    () => _pushAfterFrame(context, const ProductFormScreen()),
              ),
            ];

            const spacing = AppSpacing.sm;
            final columns = switch (constraints.maxWidth) {
              <= 340 => 3,
              <= 560 => 4,
              _ => 5,
            };
            final itemHeight = columns == 3 ? 96.0 : 90.0;
            final itemWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: AppSpacing.sm,
              children:
                  actions
                      .map(
                        (item) => SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: _QuickActionButton(
                            icon: item.icon,
                            label: item.label,
                            color: item.color,
                            onTap: item.onTap,
                          ),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            splashColor: color.withValues(alpha: 0.16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.20),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.labelSub,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
