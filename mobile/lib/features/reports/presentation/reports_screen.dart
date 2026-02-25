import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
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
import '../../billing/presentation/invoice_list_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final currFmt = NumberFormat('#,##0.00');
    final l10n = AppLocalizations.of(context)!;

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
                        label: l10n.reportsQuickStatTodaySales,
                        value: 'NPR ${currFmt.format(summary.todaySales)}',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _QuickStatCard(
                        label: l10n.reportsQuickStatPendingCredit,
                        value:
                            'NPR ${currFmt.format(summary.creditOutstanding)}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: AppSpacing.h),

            SectionHeader(l10n.reports),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ReportTile(
                    icon: Icons.health_and_safety_outlined,
                    iconColor: AppColors.primary,
                    title: l10n.businessHealth,
                    subtitle: l10n.reportsBusinessHealthSubtitle,
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
                    title: l10n.reportsSalesReportTitle,
                    subtitle: l10n.reportsSalesReportSubtitle,
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
                    title: l10n.reportsProfitReportTitle,
                    subtitle: l10n.reportsProfitReportSubtitle,
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
                    title: l10n.reportsCreditReportTitle,
                    subtitle: l10n.reportsCreditReportSubtitle,
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
                    title: l10n.creditAging,
                    subtitle: l10n.reportsCreditAgingSubtitle,
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
                    title: l10n.reportsAlertsFeedTitle,
                    subtitle: l10n.reportsAlertsFeedSubtitle,
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
                    title: l10n.reportsProductInsightsTitle,
                    subtitle: l10n.reportsProductInsightsSubtitle,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductInsightsReportScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.primary,
                    title: l10n.invoices,
                    subtitle: l10n.reportsInvoicesSubtitle,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const InvoiceListScreen(),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  _ReportTile(
                    icon: Icons.menu_book_outlined,
                    iconColor: AppColors.muted,
                    title: l10n.reportsLedgerTitle,
                    subtitle: l10n.reportsLedgerSubtitle,
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
