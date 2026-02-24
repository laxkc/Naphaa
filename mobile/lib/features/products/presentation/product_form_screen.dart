import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/product.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtl = TextEditingController(text: widget.product?.name ?? '');
  late final _sellCtl = TextEditingController(
      text: widget.product != null
          ? widget.product!.sellPrice.toStringAsFixed(2)
          : '');
  late final _costCtl = TextEditingController(
      text: widget.product != null
          ? widget.product!.costPrice.toStringAsFixed(2)
          : '');
  late final _stockCtl = TextEditingController(
      text: widget.product != null
          ? widget.product!.stockQty.toStringAsFixed(0)
          : '0');
  late final _lowStockCtl = TextEditingController(
      text: widget.product != null
          ? widget.product!.lowStockThreshold.toStringAsFixed(0)
          : '0');
  late final _categoryCtl =
      TextEditingController(text: widget.product?.category ?? '');
  late String _unit = widget.product?.unit ?? 'pcs';
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  static const _units = ['pcs', 'kg', 'g', 'L', 'mL', 'box', 'doz', 'pack'];

  @override
  void dispose() {
    _nameCtl.dispose();
    _sellCtl.dispose();
    _costCtl.dispose();
    _stockCtl.dispose();
    _lowStockCtl.dispose();
    _categoryCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          _isEdit
              ? context.tr('Edit Product', 'सामान सम्पादन')
              : context.tr('Add Product', 'सामान थप्नुहोस्'),
        ),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Category
              TextFormField(
                controller: _categoryCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'e.g. Snacks, Beverages',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Pricing row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sellCtl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Sell Price',
                        prefixText: 'NPR ',
                      ),
                      validator: (v) {
                        final p = double.tryParse(v ?? '');
                        if (p == null || p <= 0) return 'Enter valid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _costCtl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                        prefixText: 'NPR ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Stock (only for new product)
              if (!_isEdit) ...[
                TextFormField(
                  controller: _stockCtl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Opening Stock'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _lowStockCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.tr('Low Stock Threshold', 'कम स्टक सीमा'),
                  hintText: context.tr('0 to disable alert', 'अलर्ट बन्द गर्न ०'),
                ),
                validator: (v) {
                  final t = double.tryParse((v ?? '').trim().isEmpty ? '0' : v!.trim());
                  if (t == null || t < 0) {
                    return context.tr(
                      'Enter a valid threshold',
                      'मान्य सीमा लेख्नुहोस्',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Unit selector
              Text(context.tr('Unit', 'एकाइ'),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: _units.map((u) {
                  return ChoiceChip(
                    label: Text(u),
                    selected: _unit == u,
                    onSelected: (_) => setState(() => _unit = u),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _unit == u ? Colors.white : AppColors.label,
                      fontWeight: _unit == u ? FontWeight.w700 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _unit == u ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  );
                }).toList(),
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
                      : Text(
                          _isEdit
                              ? context.tr('Save Changes', 'परिवर्तन सेभ')
                              : context.tr('Add Product', 'सामान थप्नुहोस्'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(productsRepositoryProvider);
      final lowStockThreshold =
          double.tryParse(_lowStockCtl.text.trim().isEmpty ? '0' : _lowStockCtl.text.trim()) ?? 0;
      if (_isEdit) {
        final updated = widget.product!.copyWith(
          name: _nameCtl.text.trim(),
          sellPrice: double.parse(_sellCtl.text.trim()),
          costPrice: double.tryParse(_costCtl.text.trim()) ?? 0,
          lowStockThreshold: lowStockThreshold,
          unit: _unit,
          category: _categoryCtl.text.trim().isEmpty
              ? null
              : _categoryCtl.text.trim(),
        );
        await repo.updateProduct(updated);
      } else {
        await repo.addProduct(
          name: _nameCtl.text.trim(),
          sellPrice: double.parse(_sellCtl.text.trim()),
          costPrice: double.tryParse(_costCtl.text.trim()) ?? 0,
          stockQty: double.tryParse(_stockCtl.text.trim()) ?? 0,
          lowStockThreshold: lowStockThreshold,
          unit: _unit,
          category: _categoryCtl.text.trim().isEmpty
              ? null
              : _categoryCtl.text.trim(),
        );
      }
      ref.invalidate(productsListProvider);
      ref.invalidate(lowStockProductsProvider);
      if (_isEdit) ref.invalidate(productDetailProvider(widget.product!.id));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = context.tr(
          'Failed to save product. Try again.',
          'सामान सेभ गर्न सकेन। फेरि प्रयास गर्नुहोस्।',
        );
      });
    }
  }
}
