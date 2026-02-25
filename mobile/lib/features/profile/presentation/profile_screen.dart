import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(l10n.profile)),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              onRetry: () => ref.invalidate(profileProvider),
              message: e.toString(),
            ),
        data:
            (p) => SingleChildScrollView(
              child: Column(
                children: [
                  // ── avatar hero ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.h),
                    child: Column(
                      children: [
                        InitialsAvatar(
                          name: p.storeName ?? p.phone ?? 'U',
                          size: 80,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          p.storeName ?? l10n.myStoreLabel,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (p.phone != null)
                          Text(
                            p.phone!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── details card ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          AppListTile(
                            leading: const Icon(
                              Icons.phone_iphone_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.phone,
                            subtitle: p.phone ?? '—',
                            onTap: null,
                          ),
                          AppListTile(
                            leading: const Icon(
                              Icons.storefront_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.store,
                            subtitle: p.storeName ?? '—',
                            onTap: null,
                          ),
                          AppListTile(
                            leading: const Icon(
                              Icons.call_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.storePhoneLabel,
                            subtitle:
                                p.storePhone?.trim().isNotEmpty == true
                                    ? p.storePhone!
                                    : '—',
                            onTap: null,
                          ),
                          AppListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.storeAddressLabel,
                            subtitle:
                                p.storeAddress?.trim().isNotEmpty == true
                                    ? p.storeAddress!
                                    : '—',
                            onTap: null,
                          ),
                          AppListTile(
                            leading: const Icon(
                              Icons.category_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.businessTypeLabel,
                            subtitle:
                                p.businessType?.trim().isNotEmpty == true
                                    ? p.businessType!
                                    : '—',
                            onTap: null,
                          ),
                          AppListTile(
                            leading: const Icon(
                              Icons.language_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.language,
                            subtitle:
                                p.localeDefault == 'ne'
                                    ? l10n.nepaliLabel
                                    : l10n.englishLabel,
                            onTap: null,
                          ),
                          AppListTile(
                            leading: const Icon(
                              Icons.currency_rupee_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.currencyLabel,
                            subtitle:
                                p.currency?.trim().isNotEmpty == true
                                    ? p.currency!
                                    : '—',
                            onTap: null,
                          ),
                          AppListTile(
                            leading: const Icon(
                              Icons.badge_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            title: l10n.roleLabel,
                            subtitle: (p.role ?? 'owner').toUpperCase(),
                            showDivider: false,
                            onTap: null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── logout ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showConfirmDialog(
                          context,
                          title: l10n.signOutConfirmTitle,
                          body: l10n.signOutConfirmBody,
                          confirmLabel: l10n.signOutLabel,
                          destructive: false,
                        );
                        if (confirm && context.mounted) {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          if (context.mounted) {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).popUntil((route) => route.isFirst);
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
              ),
            ),
      ),
    );
  }
}

class ProfileData {
  const ProfileData({
    this.phone,
    this.storeName,
    this.storeAddress,
    this.storePhone,
    this.businessType,
    this.localeDefault,
    this.currency,
    this.role,
  });
  final String? phone;
  final String? storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? businessType;
  final String? localeDefault;
  final String? currency;
  final String? role;
}
