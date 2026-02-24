import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../customers/presentation/customer_form_screen.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_form_screen.dart';
import '../../sales/presentation/create_sale_screen.dart';
import '../../../shared/widgets/ui_kit.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final lowStock = ref.watch(lowStockProductsProvider);
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
            message: 'Failed to load dashboard',
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
        final today = DateFormat.yMMMd(
          localeCode == 'ne' ? 'ne_NP' : 'en_US',
        ).format(DateTime.now());

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
    final profitColor =
        profit >= 0 ? const Color(0xFF80CBC4) : const Color(0xFFEF9A9A);
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
                  colors: [Color(0xFF004D40), Color(0xFF00897B)],
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
                color: Colors.white.withAlpha(13),
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
                color: Colors.white.withAlpha(8),
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
                    const Icon(
                      Icons.bar_chart_rounded,
                      size: 16,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.dashboardOverview.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        today,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
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
                Container(
                  height: 1,
                  color: Colors.white.withAlpha(25),
                ),
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
                      color: Colors.white.withAlpha(25),
                    ),
                    Expanded(
                      child: _HeroStat(
                        icon: profit >= 0
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
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white60),
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
              Text(
                l10n.cashflowHealth,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: AppColors.muted,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Low stock items',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          lowStock.when(
            loading:
                () => const Text(
                  'Checking stock...',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
            error:
                (_, __) => const Text(
                  'Unable to load low stock data',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
            data: (items) {
              if (items.isEmpty) {
                return const Text(
                  'All products are above threshold.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
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
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '${p.stockQty.toStringAsFixed(0)} left',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.0,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.receipt_outlined,
                label: 'New Sale',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.inventory_2_outlined,
                label: 'Product',
                color: AppColors.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.person_add_outlined,
                label: 'Customer',
                color: AppColors.primaryLight,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CustomerFormScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.payments_outlined,
                label: 'Expense',
                color: AppColors.warning,
                onTap: () => showAppBottomSheet(
                  context,
                  child: ExpenseFormSheet(ref: ref, l10n: l10n),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
    return Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashColor: color.withAlpha(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(45),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.labelSub,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
