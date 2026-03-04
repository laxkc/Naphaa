import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/date/calendar_adapter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/reports/domain/ledger_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';

class LedgerReportScreen extends ConsumerWidget {
  const LedgerReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ledgerAsync = ref.watch(ledgerReportProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final calendarAsync = ref.watch(calendarAdapterProvider);
    final calendar =
        calendarAsync is AsyncData<CalendarAdapter>
            ? calendarAsync.value
            : CalendarAdapter(calendarMode: 'AD', localeCode: localeCode);
    final currFmt = NumberFormat('#,##0.00');
    final timeFmt = DateFormat('h:mm a');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.reportsLedgerTitle),
        backgroundColor: AppColors.surface,
      ),
      body: ledgerAsync.when(
        loading:
            () => ListView.builder(
              itemCount: 6,
              itemBuilder: (_, __) => const SkeletonListTile(),
            ),
        error:
            (e, _) => ErrorRetry(
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
                        isIn
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
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
                            '${calendar.formatBusinessDate(item.createdAt.toLocal())} • ${timeFmt.format(item.createdAt.toLocal())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          if (_correctionLink(item) case final link?)
                            Text(
                              'linked_sale_id:$link',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          if (item.metadata != null &&
                              item.metadata!.isNotEmpty)
                            Text(
                              _metadataSummary(item.metadata!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIn ? '+' : '-'}NPR ${currFmt.format(item.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
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

String _metadataSummary(Map<String, dynamic> metadata) {
  const preferredOrder = [
    'original_sale_id',
    'sale_id',
    'refund_id',
    'reason',
    'void_reason',
  ];
  final orderedEntries = <MapEntry<String, dynamic>>[];
  final seen = <String>{};
  for (final key in preferredOrder) {
    if (metadata.containsKey(key)) {
      orderedEntries.add(MapEntry(key, metadata[key]));
      seen.add(key);
    }
  }
  for (final entry in metadata.entries) {
    if (!seen.contains(entry.key)) orderedEntries.add(entry);
  }
  return orderedEntries
      .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
      .take(2)
      .map((e) => '${e.key}:${e.value}')
      .join(' • ');
}

String? _correctionLink(LedgerEntryItem item) {
  final metadata = item.metadata ?? const <String, dynamic>{};
  final candidates = [
    metadata['original_sale_id'],
    metadata['sale_id'],
    metadata['saleId'],
    metadata['source_sale_id'],
    item.saleId,
  ];
  for (final value in candidates) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}
