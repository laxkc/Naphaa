import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import 'sales_report_screen.dart';
import 'profit_report_screen.dart';
import 'credit_report_screen.dart';
import 'credit_aging_report_screen.dart';
import 'alerts_feed_screen.dart';
import 'business_health_screen.dart';
import 'ledger_report_screen.dart';
import 'product_insights_report_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final currFmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick stats
            summaryAsync.when(
              loading: () => const SkeletonListTile(),
              error: (_, __) => const SizedBox.shrink(),
              data:
                  (summary) => Row(
                    children: [
                      _QuickStatCard(
                        label: context.tr("Today's Sales", 'आजको बिक्री'),
                        value: 'NPR ${currFmt.format(summary.todaySales)}',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _QuickStatCard(
                        label: context.tr('Pending Credit', 'बाँकी उधारो'),
                        value:
                            'NPR ${currFmt.format(summary.creditOutstanding)}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: AppSpacing.h),

            SectionHeader(context.tr('Reports', 'रिपोर्टहरू')),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ReportTile(
                    icon: Icons.health_and_safety_outlined,
                    iconColor: AppColors.primary,
                    title: context.tr('Business Health', 'व्यवसाय स्वास्थ्य'),
                    subtitle: context.tr(
                      'Profit, credit risk, stock health, alerts',
                      'नाफा, उधारो जोखिम, स्टक स्वास्थ्य, अलर्ट',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BusinessHealthScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.primary,
                    title: context.tr('Sales Report', 'बिक्री रिपोर्ट'),
                    subtitle: context.tr(
                      'Revenue, transactions by period',
                      'अवधिअनुसार आम्दानी र कारोबार',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SalesReportScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.success,
                    title: context.tr('Profit Report', 'नाफा रिपोर्ट'),
                    subtitle: context.tr(
                      'Gross & net profit breakdown',
                      'कुल र खुद नाफा विवरण',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfitReportScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.credit_card_outlined,
                    iconColor: AppColors.warning,
                    title: context.tr('Credit Report', 'उधारो रिपोर्ट'),
                    subtitle: context.tr(
                      'Outstanding customer balances',
                      'ग्राहकहरूको बाँकी उधारो',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreditReportScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.schedule_outlined,
                    iconColor: AppColors.error,
                    title: context.tr('Credit Aging', 'उधारो उमेर रिपोर्ट'),
                    subtitle: context.tr(
                      'Outstanding by age buckets and risk',
                      'उमेर समूह र जोखिम अनुसार बाँकी उधारो',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreditAgingReportScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppColors.error,
                    title: context.tr('Alerts Feed', 'अलर्ट फिड'),
                    subtitle: context.tr(
                      'Actionable risk and business alerts',
                      'कार्यात्मक जोखिम र व्यवसायिक अलर्टहरू',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AlertsFeedScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.inventory_outlined,
                    iconColor: AppColors.success,
                    title: context.tr('Product Insights', 'वस्तु अन्तर्दृष्टि'),
                    subtitle: context.tr(
                      'Profit by product and dead stock',
                      'वस्तु अनुसार नाफा र नचल्ने स्टक',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductInsightsReportScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.menu_book_outlined,
                    iconColor: AppColors.muted,
                    title: context.tr('Ledger', 'लेजर'),
                    subtitle: context.tr(
                      'Unified financial audit trail',
                      'एकीकृत वित्तीय अडिट ट्रेल',
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LedgerReportScreen(),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
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
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      onTap: onTap,
    );
  }
}
