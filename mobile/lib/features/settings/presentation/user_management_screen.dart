import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('User Management', 'प्रयोगकर्ता व्यवस्थापन')),
        backgroundColor: AppColors.surface,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner card
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
                            profile.storeName ?? context.tr('Owner', 'मालिक'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            context.tr('Owner · Full access', 'मालिक · पूर्ण पहुँच'),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(label: context.tr('Owner', 'मालिक'), color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.h),
              SectionHeader(context.tr('Staff Members', 'कर्मचारी सदस्यहरू')),
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
                              context.tr('No staff members yet', 'अहिलेसम्म कर्मचारी सदस्य छैनन्'),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.label),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(
                                'Invite staff to manage your shop',
                                'पसल व्यवस्थापनका लागि कर्मचारी बोलाउनुहोस्',
                              ),
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
                  label: Text(context.tr('Invite Staff Member', 'कर्मचारी निमन्त्रणा गर्नुहोस्')),
                  onPressed: () => _showInviteDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final phoneCtl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Invite Staff', 'कर्मचारी निमन्त्रणा')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(
                'Enter the phone number of the staff member to invite.',
                'निमन्त्रणा गर्नुपर्ने कर्मचारीको फोन नम्बर लेख्नुहोस्।',
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.tr('Phone Number', 'फोन नम्बर'),
                hintText: '98XXXXXXXX',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('Cancel', 'रद्द')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(
                      'Invitation feature coming soon',
                      'निमन्त्रणा सुविधा चाँडै आउँदैछ',
                    ),
                  ),
                ),
              );
            },
            child: Text(context.tr('Send Invite', 'निमन्त्रणा पठाउनुहोस्')),
          ),
        ],
      ),
    );
  }
}
