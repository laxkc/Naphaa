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
import '../../settings/presentation/billing_settings_screen.dart';
import '../../settings/presentation/business_settings_screen.dart';
import '../../settings/presentation/tax_settings_screen.dart';
import '../../../shared/widgets/ui_kit.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final alerts = ref.watch(alertsUnreadFeedProvider);
    final setupPrompts = ref.watch(setupPromptsProvider);
    final firstRunSnapshot = ref.watch(firstRunSnapshotProvider);
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
        final profit = data.estimatedProfit;
        final credit = data.creditOutstanding;
        final lowStockCount = data.lowStockItems;

        final salesSection = [
          _KpiValue(
            label: l10n.todaySales,
            value: formatCurrency(data.todaySales, localeCode),
          ),
          _KpiValue(
            label: l10n.dashboardKpiTotalRevenue,
            value: formatCurrency(data.totalRevenue, localeCode),
          ),
          _KpiValue(
            label: l10n.dashboardKpiTransactionsCount,
            value: data.transactionsCount.toString(),
          ),
          _KpiValue(
            label: l10n.dashboardKpiAverageBill,
            value: formatCurrency(data.averageBill, localeCode),
          ),
        ];
        final paymentsSection = [
          _KpiValue(
            label: l10n.dashboardKpiCashCollected,
            value: formatCurrency(data.cashCollected, localeCode),
          ),
          _KpiValue(
            label: l10n.dashboardKpiDigitalCollected,
            value: formatCurrency(data.digitalCollected, localeCode),
          ),
          _KpiValue(
            label: l10n.dashboardKpiCreditCreated,
            value: formatCurrency(data.creditCreated, localeCode),
          ),
          _KpiValue(
            label: l10n.dashboardKpiCreditCollected,
            value: formatCurrency(data.creditCollected, localeCode),
          ),
        ];
        final inventorySection = [
          _KpiValue(
            label: l10n.dashboardKpiLowStockItems,
            value: data.lowStockItems.toString(),
          ),
          _KpiValue(
            label: l10n.dashboardKpiInventoryLoss,
            value: data.inventoryLossQty.toStringAsFixed(0),
          ),
          _KpiValue(
            label: l10n.dashboardKpiTopSellingItems,
            value:
                data.topSellingItems.isEmpty
                    ? l10n.dashboardKpiNoTopSelling
                    : data.topSellingItems.join(', '),
          ),
        ];
        final creditSection = [
          _KpiValue(
            label: l10n.creditOutstanding,
            value: formatCurrency(data.creditOutstanding, localeCode),
          ),
          _KpiValue(
            label: l10n.dashboardKpiCustomersWithDues,
            value: data.customersWithDues.toString(),
          ),
          _KpiValue(
            label: l10n.dashboardKpiOverdueCredit,
            value: formatCurrency(data.overdueCredit, localeCode),
          ),
        ];
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
                // ── header ────────────────────────────────────────────────
                _DashboardHeader(alerts: alerts, l10n: l10n, today: today),
                const SizedBox(height: AppSpacing.md),

                // ── 2×2 metric tiles ──────────────────────────────────────
                _MetricTilesGrid(
                  sales: sales,
                  profit: profit,
                  credit: credit,
                  lowStockCount: lowStockCount,
                  localeCode: localeCode,
                  l10n: l10n,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── primary actions + expandable more ─────────────────────
                _PrimaryActions(),
                const SizedBox(height: AppSpacing.md),

                // ── first-run / setup prompts ─────────────────────────────
                _FirstRunCard(snapshot: firstRunSnapshot),
                if (firstRunSnapshot.asData?.value.isEmptyBusiness == true)
                  const SizedBox(height: AppSpacing.md),
                _SetupPromptsCard(prompts: setupPrompts),
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
                _KpiSectionCard(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.sales,
                  metrics: salesSection,
                ),
                const SizedBox(height: AppSpacing.md),
                _KpiSectionCard(
                  icon: Icons.payments_outlined,
                  title: l10n.dashboardSectionPayments,
                  metrics: paymentsSection,
                ),
                const SizedBox(height: AppSpacing.md),
                _KpiSectionCard(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.dashboardSectionInventory,
                  metrics: inventorySection,
                  emphasizeLast: true,
                ),
                const SizedBox(height: AppSpacing.md),
                _KpiSectionCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.dashboardSectionCredit,
                  metrics: creditSection,
                ),
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

// ─── dashboard header ─────────────────────────────────────────────────────────

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({
    required this.alerts,
    required this.l10n,
    required this.today,
  });

  final AsyncValue<List<AlertItem>> alerts;
  final AppLocalizations l10n;
  final String today;

  String _greeting(AppLocalizations l10n) {
    final hour = TimeOfDay.now().hour;
    if (hour < 12) return l10n.dashboardGreetingMorning;
    if (hour < 17) return l10n.dashboardGreetingAfternoon;
    return l10n.dashboardGreetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final storeName = profileAsync.asData?.value.storeName ?? l10n.dashboard;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      storeName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      today,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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
                              constraints:
                                  const BoxConstraints(minWidth: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              height: 16,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
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

// ─── 2×2 metric tiles ─────────────────────────────────────────────────────────

class _MetricTilesGrid extends StatelessWidget {
  const _MetricTilesGrid({
    required this.sales,
    required this.profit,
    required this.credit,
    required this.lowStockCount,
    required this.localeCode,
    required this.l10n,
  });

  final double sales;
  final double profit;
  final double credit;
  final int lowStockCount;
  final String localeCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricTile(
          label: l10n.todaySales,
          value: formatCurrency(sales, localeCode),
          icon: Icons.receipt_long_outlined,
          bgColor: AppColors.primary.withValues(alpha: 0.10),
          iconColor: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SalesListScreen(standalone: true),
            ),
          ),
        ),
        _MetricTile(
          label: l10n.netAfterExpenses,
          value: formatCurrency(profit, localeCode),
          icon:
              profit >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
          bgColor:
              profit >= 0
                  ? AppColors.success.withValues(alpha: 0.10)
                  : AppColors.error.withValues(alpha: 0.10),
          iconColor: profit >= 0 ? AppColors.success : AppColors.error,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BusinessHealthScreen()),
          ),
        ),
        _MetricTile(
          label: l10n.creditOutstanding,
          value: formatCurrency(credit, localeCode),
          icon: Icons.account_balance_wallet_outlined,
          bgColor: AppColors.warning.withValues(alpha: 0.10),
          iconColor: AppColors.warning,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreditReportScreen()),
          ),
        ),
        _MetricTile(
          label: l10n.dashboardKpiLowStockItems,
          value: lowStockCount.toString(),
          icon: Icons.inventory_2_outlined,
          bgColor:
              lowStockCount > 0
                  ? AppColors.error.withValues(alpha: 0.10)
                  : AppColors.success.withValues(alpha: 0.10),
          iconColor:
              lowStockCount > 0 ? AppColors.error : AppColors.success,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProductsScreen(standalone: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: iconColor),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.label,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── primary actions ──────────────────────────────────────────────────────────

class _PrimaryActions extends ConsumerStatefulWidget {
  const _PrimaryActions();

  @override
  ConsumerState<_PrimaryActions> createState() => _PrimaryActionsState();
}

class _PrimaryActionsState extends ConsumerState<_PrimaryActions> {

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final secondaryActions = <_QuickActionItem>[
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
        onTap: () => _pushAfterFrame(context, const CustomerFormScreen()),
      ),
      _QuickActionItem(
        icon: Icons.store_outlined,
        label: l10n.setupPromptBusinessProfileAction,
        color: AppColors.primaryDark,
        onTap:
            () => _pushAfterFrame(context, const BusinessSettingsScreen()),
      ),
      _QuickActionItem(
        icon: Icons.receipt_long_outlined,
        label: l10n.invoices,
        color: AppColors.primary,
        onTap: () => _pushAfterFrame(context, const InvoiceListScreen()),
      ),
      _QuickActionItem(
        icon: Icons.health_and_safety_outlined,
        label: l10n.businessHealth,
        color: AppColors.success,
        onTap: () => _pushAfterFrame(context, const BusinessHealthScreen()),
      ),
      _QuickActionItem(
        icon: Icons.schedule_outlined,
        label: l10n.creditAging,
        color: AppColors.warning,
        onTap:
            () => _pushAfterFrame(context, const CreditAgingReportScreen()),
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
        onTap: () => _pushAfterFrame(context, const ProductFormScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── section label ──────────────────────────────────────────────────
        Text(
          l10n.quickActionsTitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── 2 primary buttons ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    () => _pushAfterFrame(context, const CreateSaleScreen()),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.newSale),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    () => _pushAfterFrame(context, const CreditReportScreen()),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(l10n.recordPay),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── secondary actions grid ────────────────────────────────────────
        LayoutBuilder(
            builder: (context, constraints) {
              const spacing = AppSpacing.sm;
              final columns = switch (constraints.maxWidth) {
                <= 340 => 3,
                <= 560 => 4,
                _ => 5,
              };
              final itemHeight = columns == 3 ? 96.0 : 90.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) /
                  columns;

              return Wrap(
                spacing: spacing,
                runSpacing: AppSpacing.sm,
                children:
                    secondaryActions
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header skeleton
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, radius: AppRadius.sm, width: 100),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 22, radius: AppRadius.sm, width: 160),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 18, radius: AppRadius.pill, width: 80),
                  ],
                ),
              ),
              SkeletonBox(
                height: 48,
                radius: AppRadius.pill,
                width: 48,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 2×2 tile skeleton
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (_) => SkeletonBox(height: double.infinity, radius: AppRadius.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 2 button skeleton
          Row(
            children: [
              Expanded(
                child: SkeletonBox(height: 48, radius: AppRadius.md),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SkeletonBox(height: 48, radius: AppRadius.md),
              ),
            ],
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

class _KpiValue {
  const _KpiValue({required this.label, required this.value});
  final String label;
  final String value;
}

// ─── collapsible KPI section card ─────────────────────────────────────────────

class _KpiSectionCard extends StatefulWidget {
  const _KpiSectionCard({
    required this.icon,
    required this.title,
    required this.metrics,
    this.emphasizeLast = false,
  });

  final IconData icon;
  final String title;
  final List<_KpiValue> metrics;
  final bool emphasizeLast;

  @override
  State<_KpiSectionCard> createState() => _KpiSectionCardState();
}

class _KpiSectionCardState extends State<_KpiSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Row(
              children: [
                Icon(widget.icon, size: 16, color: AppColors.muted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < widget.metrics.length; i++) ...[
              _KpiRow(
                item: widget.metrics[i],
                emphasize: widget.emphasizeLast && i == widget.metrics.length - 1,
              ),
              if (i != widget.metrics.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.item, this.emphasize = false});

  final _KpiValue item;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          emphasize ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            item.label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            item.value,
            textAlign: TextAlign.right,
            maxLines: emphasize ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.label,
            ),
          ),
        ),
      ],
    );
  }
}

class _FirstRunCard extends StatelessWidget {
  const _FirstRunCard({required this.snapshot});

  final AsyncValue<FirstRunSnapshot> snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return snapshot.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (value) {
        if (!value.isEmptyBusiness) return const SizedBox.shrink();
        return AppCard(
          color: AppColors.surfaceAlt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardFirstRunTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.dashboardFirstRunSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SetupPromptsCard extends ConsumerWidget {
  const _SetupPromptsCard({required this.prompts});

  final AsyncValue<List<SetupPrompt>> prompts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return prompts.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.setupSectionTitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...items.map(
              (prompt) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _promptTitle(l10n, prompt.id),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _promptSubtitle(l10n, prompt.id),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                FilledButton.tonal(
                                  onPressed:
                                      () => _openPrompt(context, prompt.id),
                                  child: Text(
                                    _promptActionLabel(l10n, prompt.id),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final storeId = await ref
                                        .read(preferencesProvider)
                                        .getActiveStoreId();
                                    await ref
                                        .read(preferencesProvider)
                                        .dismissSetupPrompt(
                                          prompt.id,
                                          storeId: storeId,
                                        );
                                    ref.invalidate(setupPromptsProvider);
                                  },
                                  child: Text(l10n.clearLabel),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _promptTitle(AppLocalizations l10n, String id) {
    return switch (id) {
      'business_profile' => l10n.setupPromptBusinessProfileTitle,
      'tax_settings' => l10n.setupPromptTaxSettingsTitle,
      'first_product' => l10n.setupPromptFirstProductTitle,
      'first_customer' => l10n.setupPromptFirstCustomerTitle,
      'invoice_prefix' => l10n.setupPromptInvoicePrefixTitle,
      _ => l10n.setupSectionTitle,
    };
  }

  String _promptSubtitle(AppLocalizations l10n, String id) {
    return switch (id) {
      'business_profile' => l10n.setupPromptBusinessProfileSubtitle,
      'tax_settings' => l10n.setupPromptTaxSettingsSubtitle,
      'first_product' => l10n.setupPromptFirstProductSubtitle,
      'first_customer' => l10n.setupPromptFirstCustomerSubtitle,
      'invoice_prefix' => l10n.setupPromptInvoicePrefixSubtitle,
      _ => '',
    };
  }

  String _promptActionLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'business_profile' => l10n.setupPromptBusinessProfileAction,
      'tax_settings' => l10n.setupPromptTaxSettingsAction,
      'first_product' => l10n.setupPromptFirstProductAction,
      'first_customer' => l10n.setupPromptFirstCustomerAction,
      'invoice_prefix' => l10n.setupPromptInvoicePrefixAction,
      _ => l10n.openLabel,
    };
  }

  void _openPrompt(BuildContext context, String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      switch (id) {
        case 'business_profile':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BusinessSettingsScreen()),
          );
          break;
        case 'tax_settings':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaxSettingsScreen()),
          );
          break;
        case 'first_product':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          break;
        case 'first_customer':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
          break;
        case 'invoice_prefix':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BillingSettingsScreen()),
          );
          break;
      }
    });
  }
}

// ─── quick action primitives (reused by _PrimaryActions) ─────────────────────

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
