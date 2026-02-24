import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../sales_controller.dart';
import '../sales_state.dart';

class CreateSaleScreen extends ConsumerWidget {
  const CreateSaleScreen({super.key});

  double _priceForSelected(SalesState state, String productId) {
    final fromProducts =
        state.products.where((p) => p.id == productId).firstOrNull;
    if (fromProducts != null) return fromProducts.sellPrice;
    final fromRecent =
        state.recentProducts.where((p) => p.id == productId).firstOrNull;
    return fromRecent?.sellPrice ?? 0;
  }

  Future<void> _showQuickCreateProductDialog(
    BuildContext context,
    SalesController controller,
    String initialName,
  ) async {
    final nameCtrl = TextEditingController(text: initialName.trim());
    final priceCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Quick Add Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Selling price'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final price = double.tryParse(priceCtrl.text.trim());
                  if (price == null || price <= 0) return;
                  await controller.quickAddProduct(
                    name: nameCtrl.text.trim(),
                    sellPrice: price,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  Future<void> _showQuickCreditCustomerDialog(
    BuildContext context,
    WidgetRef ref,
    SalesController controller,
  ) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Quick Credit Customer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Customer name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final confirmed = await _confirmCreditRiskIfNeeded(
                    context,
                    ref,
                    customerName: nameCtrl.text,
                    phone: phoneCtrl.text,
                  );
                  if (!confirmed) return;
                  await controller.saveCreditSaleWithCustomer(
                    customerName: nameCtrl.text,
                    phone: phoneCtrl.text,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save Credit Sale'),
              ),
            ],
          ),
    );
  }

  Future<bool> _confirmCreditRiskIfNeeded(
    BuildContext context,
    WidgetRef ref, {
    required String customerName,
    required String phone,
  }) async {
    final name = customerName.trim();
    final phoneTrimmed = phone.trim();
    if (name.isEmpty) return true;

    try {
      final customers = await ref.read(customersListProvider.future);
      final riskMap = await ref.read(customerRiskMetricsProvider.future);

      final existing = customers.firstWhere((c) {
        final phoneMatch =
            phoneTrimmed.isNotEmpty && (c.phone?.trim() ?? '') == phoneTrimmed;
        final nameMatch = c.name.trim().toLowerCase() == name.toLowerCase();
        return phoneMatch || nameMatch;
      });
      final risk = riskMap[existing.id];
      if (risk == null) return true;
      final level = risk.riskLevel.toLowerCase();
      if (level != 'red' && level != 'yellow') return true;

      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final color = level == 'red' ? AppColors.error : AppColors.warning;
          final label = level == 'red' ? 'High Risk' : 'Medium Risk';
          return AlertDialog(
            title: const Text('Credit Risk Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Existing customer "${existing.name}" is marked $label.'),
                const SizedBox(height: 10),
                Text(
                  'Outstanding: NPR ${risk.outstandingAmount.toStringAsFixed(2)}',
                ),
                Text('Oldest due: ${risk.oldestDueDays} days'),
                Text('Risk score: ${risk.riskScore}'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: const Text(
                    'Continue only if you are comfortable extending more credit.',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
      return shouldProceed ?? false;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesControllerProvider);
    final controller = ref.read(salesControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final query = state.search.trim();
    final hasExactMatch =
        query.isNotEmpty &&
        state.products.any((p) => p.name.toLowerCase() == query.toLowerCase());
    final showInlineCreate = query.isNotEmpty && !hasExactMatch;

    final totalQty = state.selected.values.fold<int>(0, (s, q) => s + q);
    final totalAmt = state.selected.entries.fold<double>(0, (s, e) {
      final price = _priceForSelected(state, e.key);
      return s + price * e.value;
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('New Sale'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: AppColors.muted,
                ),
                hintText: l10n.searchProducts,
              ),
              onChanged: controller.search,
            ),
          ),
          if (state.recentProducts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: state.recentProducts.length,
                separatorBuilder:
                    (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final p = state.recentProducts[i];
                  return ActionChip(
                    label: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.label,
                      ),
                    ),
                    onPressed: () => controller.increment(p.id),
                    avatar: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.border, width: 0.8),
                    elevation: 0,
                    pressElevation: 0,
                    surfaceTintColor: Colors.transparent,
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child:
                state.loading
                    ? ListView.builder(
                      itemCount: 6,
                      itemBuilder: (_, __) => const SkeletonListTile(),
                    )
                    : state.products.isEmpty
                    ? _QuickCreateProductEmpty(
                      query: state.search,
                      onCreateQuick:
                          state.search.trim().isEmpty
                              ? null
                              : () => _showQuickCreateProductDialog(
                                context,
                                controller,
                                state.search,
                              ),
                    )
                    : ListView.separated(
                      itemCount:
                          state.products.length + (showInlineCreate ? 1 : 0),
                      separatorBuilder:
                          (_, __) => const Divider(
                            indent: AppSpacing.lg,
                            endIndent: AppSpacing.lg,
                            height: 0,
                          ),
                      itemBuilder: (_, i) {
                        if (showInlineCreate && i == 0) {
                          return ListTile(
                            leading: const Icon(
                              Icons.add_box_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text('Create "$query" quickly'),
                            subtitle: const Text(
                              'Enter only selling price and continue sale',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap:
                                () => _showQuickCreateProductDialog(
                                  context,
                                  controller,
                                  query,
                                ),
                          );
                        }
                        final index = i - (showInlineCreate ? 1 : 0);
                        final p = state.products[index];
                        final qty = state.selected[p.id] ?? 0;
                        return _ProductRow(
                          name: p.name,
                          price: p.sellPrice,
                          stock: p.stockQty.toInt(),
                          qty: qty,
                          localeCode: localeCode,
                          onIncrement: () => controller.increment(p.id),
                          onDecrement: () => controller.decrement(p.id),
                        );
                      },
                    ),
          ),
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: InlineBanner(
                message: state.message!,
                type:
                    state.message!.toLowerCase().contains('fail') ||
                            state.message!.toLowerCase().contains('error')
                        ? BannerType.error
                        : BannerType.success,
              ),
            ),
          _CartFooter(
            l10n: l10n,
            totalQty: totalQty,
            totalAmt: totalAmt,
            localeCode: localeCode,
            loading: state.loading,
            onCash: controller.saveCashSale,
            onCredit:
                () => _showQuickCreditCustomerDialog(context, ref, controller),
          ),
        ],
      ),
    );
  }
}

class _QuickCreateProductEmpty extends StatelessWidget {
  const _QuickCreateProductEmpty({
    required this.query,
    required this.onCreateQuick,
  });
  final String query;
  final VoidCallback? onCreateQuick;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        subtitle: 'Search a product name and quick create it from here.',
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 34,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No match for "$query"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onCreateQuick,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Create Product Quickly'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.name,
    required this.price,
    required this.stock,
    required this.qty,
    required this.localeCode,
    required this.onIncrement,
    required this.onDecrement,
  });
  final String name;
  final double price;
  final int stock;
  final int qty;
  final String localeCode;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final inCart = qty > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              inCart ? AppColors.primary.withAlpha(20) : AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: inCart ? AppColors.primary : AppColors.muted,
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: inCart ? FontWeight.w600 : FontWeight.w500,
          color: AppColors.label,
        ),
      ),
      subtitle: Text(
        '${formatCurrency(price, localeCode)}  ·  Stock $stock',
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: _QuantityStepper(
        qty: qty,
        onIncrement: onIncrement,
        onDecrement: onDecrement,
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return GestureDetector(
        onTap: onIncrement,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
        ),
      );
    }
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$qty',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  const _CartFooter({
    required this.l10n,
    required this.totalQty,
    required this.totalAmt,
    required this.localeCode,
    required this.loading,
    required this.onCash,
    required this.onCredit,
  });
  final AppLocalizations l10n;
  final int totalQty;
  final double totalAmt;
  final String localeCode;
  final bool loading;
  final VoidCallback onCash;
  final VoidCallback onCredit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalQty > 0) ...[
            Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 15,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$totalQty item${totalQty != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const Spacer(),
                Text(
                  formatCurrency(totalAmt, localeCode),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading || totalQty == 0 ? null : onCash,
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: Text(
                    l10n.saveCashSale,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: loading || totalQty == 0 ? null : onCredit,
                  icon: const Icon(Icons.credit_card_outlined, size: 16),
                  label: Text(
                    l10n.saveCreditSale,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
