import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/auth_role_providers.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../profile/presentation/profile_screen.dart';
import 'business_settings_screen.dart';
import 'tax_settings_screen.dart';
import 'user_management_screen.dart';
import 'subscription_screen.dart';
import '../../sync/presentation/sync_queue_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final isOwner = ref.watch(canManageSettingsProvider);
    final canManageUsers = ref.watch(canManageUsersProvider);

    return ListView(
      children: [
        // ── Business ────────────────────────────────────────────────────
        SectionHeader(context.tr('BUSINESS', 'व्यवसाय')),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(Icons.store_outlined,
                  size: 20, color: AppColors.muted),
              title: context.tr('Business Settings', 'व्यवसाय सेटिङ'),
              subtitle: context.tr('Name, address, currency', 'नाम, ठेगाना, मुद्रा'),
              onTap: isOwner
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BusinessSettingsScreen()),
                      )
                  : null,
            ),
            AppListTile(
              leading: const Icon(Icons.receipt_outlined,
                  size: 20, color: AppColors.muted),
              title: context.tr('Tax Settings', 'कर सेटिङ'),
              subtitle: context.tr('VAT / PAN / tax rate', 'VAT / PAN / कर दर'),
              onTap: isOwner
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TaxSettingsScreen()),
                      )
                  : null,
            ),
          ],
        ),

        // ── Team ────────────────────────────────────────────────────────
        SectionHeader(context.tr('TEAM', 'टोली')),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(Icons.manage_accounts_outlined,
                  size: 20, color: AppColors.muted),
              title: context.tr('User Management', 'प्रयोगकर्ता व्यवस्थापन'),
              subtitle: context.tr('Invite staff, set roles', 'कर्मचारी बोलाउनुहोस्, भूमिका सेट गर्नुहोस्'),
              onTap: canManageUsers
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserManagementScreen()),
                      )
                  : null,
            ),
            AppListTile(
              leading: const Icon(Icons.workspace_premium_outlined,
                  size: 20, color: AppColors.muted),
              title: context.tr('Subscription', 'सदस्यता'),
              subtitle: context.tr('Plan, billing details', 'योजना, बिलिङ विवरण'),
              onTap: isOwner
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen()),
                      )
                  : null,
            ),
          ],
        ),

        // ── Preferences ─────────────────────────────────────────────────
        SectionHeader(context.tr('PREFERENCES', 'प्राथमिकताहरू')),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_outlined,
                          size: 18, color: AppColors.muted),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.language,
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'ne',
                          label: Text('नेपाली'),
                          icon: Icon(Icons.translate, size: 14)),
                      ButtonSegment(
                          value: 'en',
                          label: Text(context.tr('English', 'अंग्रेजी')),
                          icon: Icon(Icons.translate, size: 14)),
                    ],
                    selected: {locale.languageCode},
                    onSelectionChanged: (v) async =>
                        controller.setLocale(v.first),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Account ─────────────────────────────────────────────────────
        SectionHeader(context.tr('ACCOUNT', 'खाता')),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(Icons.person_outline_rounded,
                  size: 20, color: AppColors.muted),
              title: l10n.profile,
              subtitle: context.tr('View and edit your profile', 'आफ्नो प्रोफाइल हेर्नुहोस् र सम्पादन गर्नुहोस्'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),

        // ── About ───────────────────────────────────────────────────────
        SectionHeader(context.tr('ABOUT', 'बारेमा')),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(Icons.sync_problem_outlined,
                  size: 20, color: AppColors.muted),
              title: context.tr('Sync Diagnostics', 'सिंक डायग्नोस्टिक्स'),
              subtitle: context.tr('Queue, retries, sync errors', 'क्यू, पुन:प्रयास, त्रुटिहरू'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
              ),
            ),
            const Divider(height: 1),
            AppListTile(
              leading: const Icon(Icons.info_outline_rounded,
                  size: 20, color: AppColors.muted),
              title: context.tr('Version', 'संस्करण'),
              subtitle: '1.0.0',
              showDivider: false,
            ),
          ],
        ),

        // ── Danger zone ─────────────────────────────────────────────────
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context,
                title: context.tr('Sign out?', 'साइन आउट गर्ने?'),
                body: context.tr(
                  'You will be returned to the login screen.',
                  'तपाईं लगइन स्क्रिनमा फर्कनुहुनेछ।',
                ),
                confirmLabel: context.tr('Sign out', 'साइन आउट'),
                destructive: false,
              );
              if (confirm) {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                }
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(l10n.logout),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.h),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
