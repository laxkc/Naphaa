import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../products/domain/product.dart';
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
                  localeCode: localeCode,
                  today: today,
                  l10n: l10n,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── kpi row ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        title: l10n.expenses,
                        value: formatCurrency(expenses, localeCode),
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _KpiCard(
                        title: l10n.netAfterExpenses,
                        value: formatCurrency(profit, localeCode),
                        icon:
                            profit >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                        color:
                            profit >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
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
    required this.localeCode,
    required this.today,
    required this.l10n,
  });

  final double sales;
  final String localeCode;
  final String today;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004D40), Color(0xFF00897B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 16,
                color: Colors.white60,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.dashboardOverview,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Text(
                today,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            formatCurrency(sales, localeCode),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
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
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── kpi card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryBadge(icon: icon, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
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
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              color: status.color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

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
          SkeletonBox(height: 130, radius: AppRadius.xl),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 100, radius: AppRadius.lg)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 100, radius: AppRadius.lg)),
            ],
          ),
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
                          Expanded(
                            child: Text(
                              p.name.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.label,
                              ),
                            ),
                          ),
                          Text(
                            p.stockQty.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
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
