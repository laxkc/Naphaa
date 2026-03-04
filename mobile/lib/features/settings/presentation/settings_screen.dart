import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/auth_role_providers.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'billing_settings_screen.dart';
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
    final profileAsync = ref.watch(profileProvider);
    final apiRole =
        profileAsync.asData?.value.role?.toString().trim().toLowerCase();
    final effectiveCanManageSettings =
        isOwner ||
        apiRole == 'owner' ||
        apiRole == 'admin' ||
        apiRole == 'super_admin' ||
        apiRole == 'superadmin';
    final effectiveCanManageUsers =
        canManageUsers ||
        apiRole == 'owner' ||
        apiRole == 'admin' ||
        apiRole == 'super_admin' ||
        apiRole == 'superadmin';

    return ListView(
      children: [
        // ── Business ────────────────────────────────────────────────────
        SectionHeader(l10n.settingsSectionBusiness),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(
                Icons.store_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.businessSettings,
              subtitle: l10n.settingsBusinessSettingsSubtitle,
              onTap:
                  effectiveCanManageSettings
                      ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusinessSettingsScreen(),
                        ),
                      )
                      : null,
            ),
            AppListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.billingSettingsTitle,
              subtitle: l10n.settingsBillingSettingsSubtitle,
              onTap:
                  effectiveCanManageSettings
                      ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BillingSettingsScreen(),
                        ),
                      )
                      : null,
            ),
            AppListTile(
              leading: const Icon(
                Icons.receipt_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.taxSettingsTitle,
              subtitle: l10n.settingsTaxSettingsSubtitle,
              onTap:
                  effectiveCanManageSettings
                      ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TaxSettingsScreen(),
                        ),
                      )
                      : null,
            ),
          ],
        ),

        // ── Team ────────────────────────────────────────────────────────
        SectionHeader(l10n.settingsSectionTeam),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(
                Icons.manage_accounts_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.userManagementTitle,
              subtitle: l10n.settingsUserManagementSubtitle,
              onTap:
                  effectiveCanManageUsers
                      ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserManagementScreen(),
                        ),
                      )
                      : null,
            ),
            AppListTile(
              leading: const Icon(
                Icons.workspace_premium_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.subscriptionTitle,
              subtitle: l10n.settingsSubscriptionSubtitle,
              onTap:
                  effectiveCanManageSettings
                      ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      )
                      : null,
            ),
          ],
        ),

        // ── Preferences ─────────────────────────────────────────────────
        SectionHeader(l10n.settingsSectionPreferences),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.language_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.language,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'ne',
                        label: Text(l10n.nepaliLabel),
                        icon: Icon(Icons.translate, size: 14),
                      ),
                      ButtonSegment(
                        value: 'en',
                        label: Text(l10n.englishLabel),
                        icon: Icon(Icons.translate, size: 14),
                      ),
                    ],
                    selected: {locale.languageCode},
                    onSelectionChanged:
                        (v) async => controller.setLocale(v.first),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Account ─────────────────────────────────────────────────────
        SectionHeader(l10n.settingsSectionAccount),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.profile,
              subtitle: l10n.settingsProfileSubtitle,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
            ),
          ],
        ),

        // ── About ───────────────────────────────────────────────────────
        SectionHeader(l10n.settingsSectionAbout),
        _SettingsCard(
          children: [
            AppListTile(
              leading: const Icon(
                Icons.sync_problem_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.syncDiagnosticsTitle,
              subtitle: l10n.settingsSyncDiagnosticsSubtitle,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
                  ),
            ),
            const Divider(height: 1),
            AppListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.muted,
              ),
              title: l10n.versionLabel,
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
                title: l10n.signOutConfirmTitle,
                body: l10n.signOutConfirmBody,
                confirmLabel: l10n.signOutLabel,
                destructive: false,
              );
              if (confirm) {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
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
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
