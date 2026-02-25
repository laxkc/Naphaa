import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import 'alert_action_router.dart';

class AlertsFeedScreen extends ConsumerWidget {
  const AlertsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsUnreadFeedProvider);
    final readCtrl = ref.read(alertReadControllerProvider);
    final dateFmt = DateFormat('MMM d, h:mm a');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.reportsAlertsFeedTitle),
        backgroundColor: AppColors.surface,
        actions: [
          alertsAsync.maybeWhen(
            data:
                (items) =>
                    items.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                          tooltip: l10n.alertsFeedMarkAllRead,
                          onPressed: () async {
                            await readCtrl.markAllRead(items.map((e) => e.id));
                          },
                          icon: const Icon(Icons.done_all_rounded),
                        ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading:
            () => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 5,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, __) => const SkeletonListTile(),
            ),
        error:
            (e, _) =>
                ErrorRetry(onRetry: () => ref.invalidate(alertsFeedProvider)),
        data: (alerts) {
          if (alerts.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none_rounded,
              title: l10n.businessHealthNoActiveAlerts,
              subtitle: l10n.alertsFeedEverythingStableSubtitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(alertsFeedProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: alerts.length,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final a = alerts[i];
                final (accent, icon) = switch (a.severity.toLowerCase()) {
                  'critical' => (AppColors.error, Icons.warning_rounded),
                  'warn' => (AppColors.warning, Icons.warning_amber_rounded),
                  _ => (AppColors.primary, Icons.info_outline_rounded),
                };
                final canOpen = AlertActionRouter.canHandle(a);
                return AppCard(
                  onTap:
                      canOpen ? () => AlertActionRouter.open(context, a) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(icon, size: 18, color: accent),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.body,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MetaChip(
                            label: a.type.replaceAll('_', ' '),
                            color: accent,
                          ),
                          if (a.createdAt != null)
                            _MetaChip(
                              label: dateFmt.format(a.createdAt!.toLocal()),
                              color: AppColors.muted,
                              outlined: true,
                            ),
                          if (a.actionType != null && a.actionType!.isNotEmpty)
                            _MetaChip(
                              label: a.actionType!.replaceAll('_', ' '),
                              color: AppColors.primary,
                              outlined: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await readCtrl.markRead(a.id);
                            },
                            icon: const Icon(Icons.done_rounded, size: 16),
                            label: Text(l10n.alertsFeedMarkRead),
                          ),
                          if (canOpen) ...[
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed:
                                  () => AlertActionRouter.open(context, a),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                              ),
                              label: Text(l10n.openLabel),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? AppColors.surface : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: outlined ? AppColors.border : color.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: outlined ? AppColors.muted : color,
        ),
      ),
    );
  }
}
