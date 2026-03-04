import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/sync_debug_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rowsAsync = ref.watch(syncQueueRowsProvider);
    final syncState = ref.watch(syncCoordinatorProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.syncDiagnosticsTitle),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: l10n.clearFailedRowsTooltip,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (dialogContext) => AlertDialog(
                      title: Text(l10n.clearFailedRowsConfirmTitle),
                      content: Text(l10n.clearFailedRowsConfirmBody),
                      actions: [
                        TextButton(
                          onPressed:
                              () => Navigator.of(dialogContext).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed:
                              () => Navigator.of(dialogContext).pop(true),
                          child: Text(l10n.clearFailedAction),
                        ),
                      ],
                    ),
              );
              if (confirmed != true || !context.mounted) return;

              final db = await ref.read(localDatabaseProvider).database;
              final deleted = await db.delete(
                'sync_queue',
                where: "status IN ('failed', 'blocked')",
              );
              ref.invalidate(syncQueueRowsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.clearedFailedRowsCount(deleted))),
                );
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          IconButton(
            tooltip: l10n.retrySyncTooltip,
            onPressed:
                syncState.syncing
                    ? null
                    : () async {
                      await ref
                          .read(syncCoordinatorProvider.notifier)
                          .triggerNow();
                      ref.invalidate(syncQueueRowsProvider);
                    },
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: l10n.refreshLabel,
            onPressed: () => ref.invalidate(syncQueueRowsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (syncState.lastError?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: InlineBanner(
                type:
                    (syncState.lastError?.contains('Server has newer data') ??
                            false)
                        ? BannerType.warning
                        : BannerType.info,
                message: syncState.lastError!,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: Row(
                children: [
                  _MiniStat(
                    label: l10n.pendingLabel,
                    value: '${syncState.pendingCount}',
                    color: AppColors.warning,
                  ),
                  _MiniStat(
                    label: l10n.ackedLabel,
                    value: '${syncState.lastAcked}',
                    color: AppColors.success,
                  ),
                  _MiniStat(
                    label: l10n.failedLabel,
                    value: '${syncState.lastFailed}',
                    color:
                        syncState.lastFailed > 0
                            ? AppColors.error
                            : AppColors.muted,
                  ),
                  _MiniStat(
                    label: 'ms',
                    value: '${syncState.lastDurationMs ?? 0}',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: rowsAsync.when(
              loading:
                  () => ListView.builder(
                    itemCount: 6,
                    itemBuilder: (_, __) => const SkeletonListTile(),
                  ),
              error:
                  (e, _) => ErrorRetry(
                    onRetry: () => ref.invalidate(syncQueueRowsProvider),
                    message: e.toString(),
                  ),
              data: (rows) {
                if (rows.isEmpty) {
                  return EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: l10n.noSyncQueueItemsTitle,
                    subtitle: l10n.noSyncQueueItemsSubtitle,
                  );
                }
                final problemRows =
                    rows
                        .where(
                          (r) => r.status == 'failed' || r.status == 'blocked',
                        )
                        .toList();
                final invalidRows =
                    problemRows
                        .where(
                          (r) => (r.lastError ?? '').toLowerCase().contains(
                            'invalid',
                          ),
                        )
                        .length;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: rows.length + (problemRows.isEmpty ? 0 : 1),
                  separatorBuilder:
                      (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    if (problemRows.isNotEmpty && i == 0) {
                      return InlineBanner(
                        type:
                            invalidRows > 0
                                ? BannerType.warning
                                : BannerType.error,
                        message:
                            invalidRows > 0
                                ? l10n.syncDiagnosticsInvalidRowsBanner(
                                  invalidRows,
                                )
                                : l10n.syncDiagnosticsFailedRowsBanner(
                                  problemRows.length,
                                ),
                      );
                    }
                    final row = rows[problemRows.isEmpty ? i : i - 1];
                    final isConflict = (row.lastError ?? '').contains(
                      'Server has newer data',
                    );
                    final isInvalid = (row.lastError ?? '')
                        .toLowerCase()
                        .contains('invalid');
                    final color = switch (row.status) {
                      'failed' =>
                        isConflict || isInvalid
                            ? AppColors.warning
                            : AppColors.error,
                      'blocked' => AppColors.error,
                      'archived' => AppColors.muted,
                      'pending' => AppColors.warning,
                      'syncing' => AppColors.primary,
                      _ => AppColors.success,
                    };
                    return AppCard(
                      onTap: () => _showDetail(context, row, l10n),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusChip(
                                label: _statusLabel(l10n, row.status),
                                color: color,
                              ),
                              if (isInvalid) ...[
                                const SizedBox(width: AppSpacing.xs),
                                StatusChip(
                                  label: l10n.invalidLabel,
                                  color: AppColors.warning,
                                ),
                              ],
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '${row.entity}.${row.operation}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.label,
                                  ),
                                ),
                              ),
                              Text(
                                '#${row.id}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            row.entityId ?? row.opId ?? '—',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          if ((row.lastError?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(
                                row.lastError!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Text(
                                l10n.retryCountShort(row.retryCount),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  row.nextRetryAt != null
                                      ? '${l10n.nextLabel}: ${_displayTs(row.nextRetryAt!)}'
                                      : _displayTs(
                                        row.updatedAt ?? row.createdAt,
                                      ),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    SyncQueueRowData row,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.entity}.${row.operation}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                _kv(l10n.statusLabel, row.status),
                _kv(l10n.entityIdLabel, row.entityId ?? '—'),
                _kv(l10n.opIdLabel, row.opId ?? '—'),
                _kv(l10n.retriesLabel, '${row.retryCount}'),
                _kv(l10n.createdLabel, _displayTs(row.createdAt)),
                _kv(l10n.updatedLabel, _displayTs(row.updatedAt ?? '—')),
                if ((row.lastError?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.lastErrorLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SelectableText(row.lastError!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: row.lastError!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.copiedErrorDetails)),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(l10n.copyLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(k, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status.toLowerCase()) {
      case 'failed':
        return l10n.failedLabel.toUpperCase();
      case 'pending':
        return l10n.pendingLabel.toUpperCase();
      case 'syncing':
        return l10n.syncingShort.toUpperCase();
      case 'blocked':
        return 'BLOCKED';
      case 'archived':
        return 'ARCHIVED';
      default:
        return l10n.ackedLabel.toUpperCase();
    }
  }

  String _displayTs(String raw) {
    if (raw == '—') return raw;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final dt = parsed.toLocal();
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd $hh:$mi';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
