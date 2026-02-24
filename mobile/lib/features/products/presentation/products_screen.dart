import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/auth_role_providers.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'stock_adjustment_screen.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(productsListProvider);
    final canAdjustStock = ref.watch(canAdjustStockProvider);

    return Column(
      children: [
        // ── search bar ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppColors.muted,
                    ),
                    hintText: 'Search products…',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => const ProductFormScreen(),
                    ))
                    .then((_) => ref.invalidate(productsListProvider)),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.addProduct),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
              ),
            ],
          ),
        ),

        // ── list ─────────────────────────────────────────────────────────
        Expanded(
          child: products.when(
            loading:
                () => ListView.builder(
                  itemCount: 6,
                  itemBuilder: (_, __) => const SkeletonListTile(),
                ),
            error:
                (_, __) => ErrorRetry(
                  onRetry: () => ref.invalidate(productsListProvider),
                  message: 'Failed to load products',
                ),
            data:
                (items) =>
                    items.isEmpty
                        ? EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: l10n.manageProducts,
                          subtitle: 'Tap "Add Product" to get started.',
                          action: l10n.addProduct,
                          onAction: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (_) => const ProductFormScreen(),
                              ))
                              .then((_) => ref.invalidate(productsListProvider)),
                        )
                        : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder:
                              (_, __) => const Divider(
                                indent: 72,
                                endIndent: AppSpacing.lg,
                                height: 0,
                              ),
                          itemBuilder: (_, i) {
                            final p = items[i];
                            final lowStock =
                                p.lowStockThreshold > 0 &&
                                p.stockQty <= p.lowStockThreshold;
                            return Dismissible(
                              key: ValueKey(p.id),
                              direction: DismissDirection.endToStart,
                              background: _DeleteBg(),
                              confirmDismiss:
                                  (_) => showConfirmDialog(
                                    context,
                                    title: 'Delete product?',
                                    body:
                                        '"${p.name}" will be permanently removed.',
                                  ),
                              onDismissed: (_) async {
                                // deletion handled by provider
                                ref.invalidate(productsListProvider);
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.xs,
                                ),
                                leading: InitialsAvatar(name: p.name, size: 40),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.label,
                                        ),
                                      ),
                                    ),
                                    if (lowStock)
                                      StatusChip(
                                        label: 'Low stock',
                                        color: AppColors.warning,
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Stock  ${p.stockQty.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Rs ${p.sellPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.label,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    IconButton(
                                      tooltip: 'Adjust stock',
                                      onPressed: canAdjustStock
                                          ? () => Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                builder: (_) =>
                                                    StockAdjustmentScreen(
                                                  productId: p.id,
                                                  productName: p.name,
                                                  currentStock: p.stockQty,
                                                ),
                                              ))
                                              .then((_) => ref.invalidate(
                                                  productsListProvider))
                                          : null,
                                      icon: const Icon(
                                        Icons.tune_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailScreen(productId: p.id),
                                    ))
                                    .then((_) =>
                                        ref.invalidate(productsListProvider)),
                                onLongPress: canAdjustStock
                                    ? () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                          builder: (_) => StockAdjustmentScreen(
                                            productId: p.id,
                                            productName: p.name,
                                            currentStock: p.stockQty,
                                          ),
                                        ))
                                        .then((_) => ref.invalidate(
                                            productsListProvider))
                                    : null,
                              ),
                            );
                          },
                        ),
          ),
        ),
      ],
    );
  }

}

// ─── swipe delete background ──────────────────────────────────────────────────

class _DeleteBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      color: AppColors.errorBg,
      child: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.error,
        size: 22,
      ),
    );
  }
}
