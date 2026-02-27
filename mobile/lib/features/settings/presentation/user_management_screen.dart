import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.userManagementTitle),
        backgroundColor: AppColors.surface,
      ),
      body: profileAsync.when(
        loading:
            () => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                SkeletonListTile(),
                SizedBox(height: AppSpacing.sm),
                SkeletonListTile(),
              ],
            ),
        error:
            (_, __) => ErrorRetry(
              onRetry: () => ref.invalidate(profileProvider),
            ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.manage_accounts_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.settingsUserManagementSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.person,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.storeName ?? l10n.ownerLabel,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            l10n.userManagementOwnerFullAccess,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(label: l10n.ownerLabel, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.userManagementStaffMembers,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.group_add_outlined,
                                size: 32, color: AppColors.muted),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.userManagementNoStaffMembers,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.label),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.userManagementInviteStaffSubtitle,
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(l10n.userManagementInviteStaffMember),
                  onPressed: () => _showInviteDialog(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phoneCtl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.userManagementInviteStaffTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.userManagementInviteStaffDialogBody,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumberLabel,
                hintText: '98XXXXXXXX',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.userManagementInviteComingSoon,
                  ),
                ),
              );
            },
            child: Text(l10n.userManagementSendInvite),
          ),
        ],
      ),
    );
  }
}
