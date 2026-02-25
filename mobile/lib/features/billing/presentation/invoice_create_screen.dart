import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/invoice_models.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  ConsumerState<InvoiceCreateScreen> createState() =>
      _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerIdCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final List<_LineDraft> _lines = [const _LineDraft()];
  bool _issuing = false;
  String? _error;

  @override
  void dispose() {
    _customerIdCtrl.dispose();
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingLangAsync = ref.watch(billingLanguageCodeProvider);
    final billingLang =
        billingLangAsync.asData?.value ??
        Localizations.localeOf(context).languageCode;
    return Localizations.override(
      context: context,
      locale: Locale(billingLang),
      child: Builder(builder: (context) => _buildScaffold(context)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Create Invoice', 'इनभ्वाइस बनाउनुहोस्')),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (_error != null) ...[
              InlineBanner(message: _error!, type: BannerType.error),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Invoice Details', 'इनभ्वाइस विवरण'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _customerIdCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        'Customer ID (optional)',
                        'ग्राहक ID (वैकल्पिक)',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('Invoice Discount', 'इनभ्वाइस छुट'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: context.tr('Notes', 'नोट'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('Items', 'सामानहरू'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            () =>
                                setState(() => _lines.add(const _LineDraft())),
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('Add Line', 'लाइन थप्नुहोस्')),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...List.generate(
                    _lines.length,
                    (i) => _LineEditor(
                      key: ValueKey('line_$i'),
                      initial: _lines[i],
                      onChanged: (next) => _lines[i] = next,
                      onRemove:
                          _lines.length == 1
                              ? null
                              : () => setState(() => _lines.removeAt(i)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _issuing ? null : _saveDraftOnly,
                    child: Text(context.tr('Save Draft', 'ड्राफ्ट सेभ')),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _issuing ? null : _saveAndIssue,
                    child: Text(
                      _issuing
                          ? context.tr('Issuing...', 'जारी गर्दै...')
                          : context.tr(
                            'Issue Invoice',
                            'इनभ्वाइस जारी गर्नुहोस्',
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDraftOnly() async {
    await _submit(issue: false);
  }

  Future<void> _saveAndIssue() async {
    await _submit(issue: true);
  }

  Future<void> _submit({required bool issue}) async {
    setState(() {
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final storeId = await ref.read(preferencesProvider).getActiveStoreId();
    if (storeId == null || storeId.isEmpty) {
      setState(() {
        _error = context.tr(
          'No active business/store found. Please login again.',
          'सक्रिय व्यवसाय/स्टोर भेटिएन। फेरि लगइन गर्नुहोस्।',
        );
      });
      return;
    }

    final lines =
        _lines
            .where((l) => l.name.trim().isNotEmpty)
            .map(
              (l) => InvoiceDraftLineInput(
                productId:
                    l.productId.trim().isEmpty ? null : l.productId.trim(),
                productNameSnapshot: l.name.trim(),
                unitSnapshot: l.unit.trim().isEmpty ? null : l.unit.trim(),
                quantity: l.quantity,
                unitPrice: l.unitPrice,
              ),
            )
            .toList();
    if (lines.isEmpty) {
      setState(() {
        _error = context.tr(
          'Add at least one item',
          'कम्तीमा एक सामान थप्नुहोस्',
        );
      });
      return;
    }

    setState(() => _issuing = true);
    try {
      final repo = ref.read(billingRepositoryProvider);
      final invoiceId = await repo.saveDraft(
        InvoiceDraftInput(
          businessId: storeId,
          customerId:
              _customerIdCtrl.text.trim().isEmpty
                  ? null
                  : _customerIdCtrl.text.trim(),
          items: lines,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          invoiceDiscountAmount:
              double.tryParse(_discountCtrl.text.trim()) ?? 0,
        ),
      );
      if (issue) {
        await repo.issueInvoice(invoiceId: invoiceId);
        try {
          await ref
              .read(invoicePdfServiceProvider)
              .generateInvoicePdf(invoiceId);
        } catch (_) {
          // Invoice stays issued if PDF generation fails; user can retry from detail.
        }
      }
      if (!mounted) return;
      ref.invalidate(invoicesListProvider);
      Navigator.of(context).pop(invoiceId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
      });
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }
}

class _LineDraft {
  const _LineDraft({
    this.productId = '',
    this.name = '',
    this.unit = 'pcs',
    this.quantity = 1,
    this.unitPrice = 0,
  });

  final String productId;
  final String name;
  final String unit;
  final double quantity;
  final double unitPrice;

  _LineDraft copyWith({
    String? productId,
    String? name,
    String? unit,
    double? quantity,
    double? unitPrice,
  }) => _LineDraft(
    productId: productId ?? this.productId,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
  );
}

class _LineEditor extends StatefulWidget {
  const _LineEditor({
    super.key,
    required this.initial,
    required this.onChanged,
    this.onRemove,
  });

  final _LineDraft initial;
  final ValueChanged<_LineDraft> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  late final TextEditingController _productIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _productIdCtrl = TextEditingController(text: widget.initial.productId);
    _nameCtrl = TextEditingController(text: widget.initial.name);
    _unitCtrl = TextEditingController(text: widget.initial.unit);
    _qtyCtrl = TextEditingController(text: widget.initial.quantity.toString());
    _priceCtrl = TextEditingController(
      text: widget.initial.unitPrice.toString(),
    );
    _emit();
  }

  @override
  void dispose() {
    _productIdCtrl.dispose();
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      _LineDraft(
        productId: _productIdCtrl.text,
        name: _nameCtrl.text,
        unit: _unitCtrl.text,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0,
        unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('Item name', 'सामानको नाम'),
                    ),
                    onChanged: (_) => _emit(),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? context.tr('Required', 'अनिवार्य')
                                : null,
                  ),
                ),
                if (widget.onRemove != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _productIdCtrl,
              decoration: InputDecoration(
                labelText: context.tr(
                  'Product ID (optional)',
                  'उत्पादन ID (वैकल्पिक)',
                ),
              ),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('Qty', 'परिमाण'),
                    ),
                    onChanged: (_) => _emit(),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) {
                        return context.tr('Qty > 0', 'परिमाण ० भन्दा बढी');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _unitCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('Unit', 'एकाइ'),
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('Rate', 'दर'),
                    ),
                    onChanged: (_) => _emit(),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) {
                        return context.tr('Invalid', 'अमान्य');
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
