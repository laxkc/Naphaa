import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/auth_role_providers.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/stock_movement.dart';
import 'product_form_screen.dart';
import 'stock_adjustment_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final movementsAsync = ref.watch(stockMovementsProvider(productId));
    final currFmt = NumberFormat('#,##0.00');
    final canAdjustStock = ref.watch(canAdjustStockProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.productDetailsTitle),
        backgroundColor: AppColors.surface,
        actions: [
          productAsync.whenOrNull(
                data:
                    (product) =>
                        product != null
                            ? IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed:
                                  () => Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ProductFormScreen(
                                                product: product,
                                              ),
                                        ),
                                      )
                                      .then((_) {
                                        ref.invalidate(
                                          productDetailProvider(productId),
                                        );
                                        ref.invalidate(productsListProvider);
                                      }),
                            )
                            : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorRetry(
              onRetry: () => ref.invalidate(productDetailProvider(productId)),
            ),
        data: (product) {
          if (product == null) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.productNotFoundTitle,
              subtitle: l10n.productNotFoundSubtitle,
            );
          }
          final isLowStock =
              product.lowStockThreshold > 0 &&
              product.stockQty <= product.lowStockThreshold;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Center(
                              child: Text(
                                product.name.isNotEmpty
                                    ? product.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (product.category != null)
                                  Text(
                                    product.category!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isLowStock
                                      ? AppColors.warningBg
                                      : AppColors.successBg,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  product.stockQty.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isLowStock
                                            ? AppColors.warning
                                            : AppColors.success,
                                  ),
                                ),
                                Text(
                                  product.unit,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isLowStock
                                            ? AppColors.warning
                                            : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.h),
                      Row(
                        children: [
                          _MetricTile(
                            label: l10n.sellPriceLabel,
                            value: '${l10n.nprLabel} ${currFmt.format(product.sellPrice)}',
                            color: AppColors.success,
                          ),
                          _MetricTile(
                            label: l10n.costPriceLabel,
                            value: '${l10n.nprLabel} ${currFmt.format(product.costPrice)}',
                            color: AppColors.muted,
                          ),
                          _MetricTile(
                            label: l10n.marginLabel,
                            value: '${product.margin.toStringAsFixed(1)}%',
                            color:
                                product.margin > 0
                                    ? AppColors.success
                                    : AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(l10n.adjustStockLabel),
                    onPressed:
                        canAdjustStock
                            ? () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StockAdjustmentScreen(
                                          productId: product.id,
                                          productName: product.name,
                                          currentStock: product.stockQty,
                                        ),
                                  ),
                                )
                                .then((_) {
                                  ref.invalidate(
                                    productDetailProvider(productId),
                                  );
                                  ref.invalidate(
                                    stockMovementsProvider(productId),
                                  );
                                  ref.invalidate(productsListProvider);
                                })
                            : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(l10n.stockHistoryTitle),
                const SizedBox(height: AppSpacing.sm),
                movementsAsync.when(
                  loading:
                      () => Column(
                        children: List.generate(
                          4,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm),
                            child: SkeletonListTile(),
                          ),
                        ),
                      ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (movements) {
                    if (movements.isEmpty) {
                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              l10n.noStockMovementsYetTitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ),
                      );
                    }
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children:
                            movements.asMap().entries.map((e) {
                              final i = e.key;
                              final m = e.value;
                              return Column(
                                children: [
                                  if (i > 0) const Divider(height: 1),
                                  _MovementTile(movement: m),
                                ],
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.h),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});
  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');
    final isAdd = movement.isAddition;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAdd ? AppColors.successBg : AppColors.errorBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isAdd ? Icons.add_rounded : Icons.remove_rounded,
              size: 16,
              color: isAdd ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.reason,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (movement.note != null && movement.note!.isNotEmpty)
                  Text(
                    movement.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  fmt.format(movement.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            '${isAdd ? '+' : ''}${movement.delta.toStringAsFixed(movement.delta == movement.delta.roundToDouble() ? 0 : 1)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isAdd ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
