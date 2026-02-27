import 'package:flutter/material.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.subscriptionTitle),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          l10n.subscriptionFreePlanBadge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.subscriptionFreePlanTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.subscriptionFreePlanSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: _PlanMetric(
                      label: l10n.subscriptionFeatureBasicReports,
                      value: '4',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PlanMetric(
                      label: l10n.subscriptionFeatureCloudSync,
                      value: 'Pro',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.subscriptionFreePlanIncludes,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _FeatureTile(
                    icon: Icons.point_of_sale_outlined,
                    title: l10n.subscriptionFeatureSalesRecording,
                    subtitle: l10n.subscriptionFeatureSalesRecordingSubtitle,
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.subscriptionFeatureProductManagement,
                    subtitle: l10n.subscriptionFeatureProductManagementSubtitle,
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.people_outline_rounded,
                    title: l10n.subscriptionFeatureCustomerLedger,
                    subtitle: l10n.subscriptionFeatureCustomerLedgerSubtitle,
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.bar_chart_rounded,
                    title: l10n.subscriptionFeatureBasicReports,
                    subtitle: l10n.subscriptionFeatureBasicReportsSubtitle,
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.cloud_sync_outlined,
                    title: l10n.subscriptionFeatureCloudSync,
                    subtitle: l10n.subscriptionFeatureCloudSyncSubtitle,
                    included: false,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.subscriptionFeatureInvoiceGeneration,
                    subtitle: l10n.subscriptionFeatureInvoiceGenerationSubtitle,
                    included: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: Text(l10n.subscriptionUpgradeToPro),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.subscriptionProComingSoon,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.included,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          size: 20, color: included ? AppColors.primary : AppColors.muted),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: included ? AppColors.label : AppColors.muted,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: Icon(
        included ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
        size: 18,
        color: included ? AppColors.success : AppColors.muted,
      ),
    );
  }
}
