import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  const StockAdjustmentScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.currentStock,
  });
  final String productId;
  final String productName;
  final double currentStock;

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState
    extends ConsumerState<StockAdjustmentScreen> {
  final _qtyCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  bool _isAdd = true;
  String _reason = 'RESTOCK';
  bool _saving = false;
  String? _error;

  static const _addReasons = ['RESTOCK', 'COUNT_CORRECTION', 'RETURN', 'OTHER'];
  static const _removeReasons = [
    'SALE',
    'DAMAGE',
    'EXPIRED',
    'COUNT_CORRECTION',
    'OTHER'
  ];

  List<String> get _reasons => _isAdd ? _addReasons : _removeReasons;

  @override
  void dispose() {
    _qtyCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.adjustStockLabel),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product summary card
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.productName,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          l10n.currentStockValue(
                            widget.currentStock.toStringAsFixed(0),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.h),

            // Add / Remove toggle
            Text(
              l10n.typeLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _TypeBtn(
                    label: l10n.addStockLabel,
                    icon: Icons.add_rounded,
                    selected: _isAdd,
                    color: AppColors.success,
                    onTap: () {
                      setState(() {
                        _isAdd = true;
                        _reason = 'RESTOCK';
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TypeBtn(
                    label: l10n.removeStockLabel,
                    icon: Icons.remove_rounded,
                    selected: !_isAdd,
                    color: AppColors.error,
                    onTap: () {
                      setState(() {
                        _isAdd = false;
                        _reason = 'DAMAGE';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quantity
            TextFormField(
              controller: _qtyCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.quantityLabel,
                hintText: l10n.egTenHint,
                prefixIcon: Icon(
                  _isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: _isAdd ? AppColors.success : AppColors.error,
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Reason chips
            Text(
              l10n.reasonLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: _reasons.map((r) {
                return ChoiceChip(
                  label: Text(r),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _reason == r ? Colors.white : AppColors.label,
                    fontWeight: _reason == r ? FontWeight.w700 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _reason == r ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Note
            TextField(
              controller: _noteCtl,
              decoration: InputDecoration(
                labelText: l10n.notesOptionalLabel,
                hintText: l10n.additionalDetailsHint,
              ),
              maxLines: 2,
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              InlineBanner(type: BannerType.error, message: _error!),
            ],

            const SizedBox(height: AppSpacing.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.saveAdjustmentLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyCtl.text.trim());
    if (qty == null || qty <= 0) {
      setState(
        () => _error = AppLocalizations.of(context)!.enterValidQuantity,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(productsRepositoryProvider);
      await repo.adjustStock(
        productId: widget.productId,
        delta: _isAdd ? qty : -qty,
        reason: _reason,
        note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
      );
      ref.invalidate(productsListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(productDetailProvider(widget.productId));
      ref.invalidate(stockMovementsProvider(widget.productId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = AppLocalizations.of(context)!.failedToAdjustStockTryAgain;
      });
    }
  }
}

class _TypeBtn extends StatelessWidget {
  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.muted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
