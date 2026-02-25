import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';

class LedgerReportScreen extends ConsumerWidget {
  const LedgerReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ledgerAsync = ref.watch(ledgerReportProvider);
    final currFmt = NumberFormat('#,##0.00');
    final dtFmt = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.reportsLedgerTitle),
        backgroundColor: AppColors.surface,
      ),
      body: ledgerAsync.when(
        loading: () => ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => const SkeletonListTile(),
        ),
        error: (e, _) => ErrorRetry(
          onRetry: () => ref.invalidate(ledgerReportProvider),
          message: e.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: l10n.ledgerNoEntriesTitle,
              subtitle: l10n.ledgerNoEntriesSubtitle,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final item = items[i];
              final isIn = item.direction.toUpperCase() == 'IN';
              final color = isIn ? AppColors.success : AppColors.error;
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIn ? Icons.call_received_rounded : Icons.call_made_rounded,
                        size: 18,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.entryType.toUpperCase()} • ${item.entityType}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.label,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dtFmt.format(item.createdAt.toLocal()),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                          if (item.metadata != null && item.metadata!.isNotEmpty)
                            Text(
                              item.metadata!.entries
                                  .take(2)
                                  .map((e) => '${e.key}:${e.value}')
                                  .join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIn ? '+' : '-'}NPR ${currFmt.format(item.amount)}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: color),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
