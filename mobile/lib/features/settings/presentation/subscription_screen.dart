import 'package:flutter/material.dart';
import '../../../core/l10n/context_i18n.dart';
import '../../../shared/widgets/ui_kit.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Subscription', 'सदस्यता')),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current plan card
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
                          context.tr('FREE PLAN', 'फ्री योजना'),
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
                  Text(context.tr('SME Digital Free', 'SME Digital Free'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'Access core features at no cost',
                      'मुख्य सुविधाहरू निःशुल्क प्रयोग गर्नुहोस्',
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.h),
            SectionHeader(context.tr('Free Plan Includes', 'फ्री योजनामा समावेश')),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _FeatureTile(
                    icon: Icons.point_of_sale_outlined,
                    title: context.tr('Sales Recording', 'बिक्री रेकर्डिङ'),
                    subtitle: context.tr('Unlimited cash & credit sales', 'असीमित नगद र उधारो बिक्री'),
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.inventory_2_outlined,
                    title: context.tr('Product Management', 'सामान व्यवस्थापन'),
                    subtitle: context.tr('Up to 100 products', '१०० वस्तुसम्म'),
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.people_outline_rounded,
                    title: context.tr('Customer Ledger', 'ग्राहक लेजर'),
                    subtitle: context.tr('Track credit customers', 'उधारो ग्राहक ट्रयाक गर्नुहोस्'),
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.bar_chart_rounded,
                    title: context.tr('Basic Reports', 'आधारभूत रिपोर्ट'),
                    subtitle: context.tr('Sales & credit reports', 'बिक्री र उधारो रिपोर्ट'),
                    included: true,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.cloud_sync_outlined,
                    title: context.tr('Cloud Sync', 'क्लाउड सिंक'),
                    subtitle: context.tr('Multi-device sync', 'धेरै डिभाइस सिंक'),
                    included: false,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.receipt_long_outlined,
                    title: context.tr('Invoice Generation', 'इनभ्वाइस बनाउने'),
                    subtitle: context.tr('PDF invoices & billing', 'PDF इनभ्वाइस र बिलिङ'),
                    included: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: Text(context.tr('Upgrade to Pro', 'Pro मा अपग्रेड')),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          'Pro plan coming soon. Stay tuned!',
                          'Pro योजना चाँडै आउँदैछ। प्रतीक्षा गर्नुहोस्!',
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
