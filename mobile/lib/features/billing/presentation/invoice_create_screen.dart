import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/date/calendar_adapter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/billing_calculator.dart';
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
  late final Future<Map<String, dynamic>> _billingSettingsFuture;
  DateTime? _dueDateAd;
  bool _issuing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _billingSettingsFuture = ref.read(preferencesProvider).getBillingSettings();
  }

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
    final l10n = AppLocalizations.of(context)!;
    final calendarAsync = ref.watch(calendarAdapterProvider);
    final calendar =
        calendarAsync is AsyncData<CalendarAdapter>
            ? calendarAsync.value
            : CalendarAdapter(
              calendarMode: 'AD',
              localeCode: Localizations.localeOf(context).languageCode,
            );
    final money = NumberFormat('#,##0.00', 'en_IN');
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.invoiceCreateTitle),
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
                    l10n.invoiceDetailsTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _customerIdCtrl,
                    decoration: InputDecoration(labelText: l10n.invoiceCustomerIdOptional),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.invoiceDiscountLabel,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: _issuing ? null : () => _pickDueDate(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.invoiceDueDateLabel,
                        suffixIcon:
                            _dueDateAd == null
                                ? const Icon(Icons.calendar_month_outlined)
                                : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed:
                                      _issuing
                                          ? null
                                          : () => setState(() => _dueDateAd = null),
                                ),
                      ),
                      child: Text(
                        _dueDateAd == null
                            ? '-'
                            : calendar.formatBusinessDate(_dueDateAd),
                        style: TextStyle(
                          color:
                              _dueDateAd == null
                                  ? AppColors.muted
                                  : AppColors.label,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.notesLabel,
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
                          l10n.itemsLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            () =>
                                setState(() => _lines.add(const _LineDraft())),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.invoiceAddLine),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...List.generate(
                    _lines.length,
                    (i) => _LineEditor(
                      key: ValueKey('line_$i'),
                      initial: _lines[i],
                      onChanged: (next) => setState(() => _lines[i] = next),
                      onRemove:
                          _lines.length == 1
                              ? null
                              : () => setState(() => _lines.removeAt(i)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<Map<String, dynamic>>(
              future: _billingSettingsFuture,
              builder: (context, snapshot) {
                final settings = snapshot.data ?? const <String, dynamic>{};
                final vatEnabled =
                    (settings['vat_enabled'] as bool?) ?? false;
                final vatRate =
                    (settings['vat_rate'] as num?)?.toDouble() ?? 13.0;
                final taxMode =
                    ((settings['tax_mode']?.toString().toLowerCase() ==
                            'inclusive')
                        ? BillingTaxMode.inclusive
                        : BillingTaxMode.exclusive);
                final calc = BillingCalculator.calculate(
                  lines:
                      _lines
                          .where((l) => l.name.trim().isNotEmpty)
                          .map(
                            (l) => BillingLineInput(
                              quantity: l.quantity,
                              unitPrice: l.unitPrice,
                            ),
                          )
                          .toList(),
                  vatEnabled: vatEnabled,
                  vatRatePercent: vatRate,
                  taxMode: taxMode,
                  invoiceDiscountAmount: discount,
                );
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SummaryRow(
                        label: l10n.subtotalLabel,
                        value: '${l10n.nprLabel} ${money.format(calc.subtotal)}',
                      ),
                      _SummaryRow(
                        label: l10n.discountLabel,
                        value:
                            '${l10n.nprLabel} ${money.format(calc.discountAmount)}',
                      ),
                      _SummaryRow(
                        label: l10n.vatLabel,
                        value: '${l10n.nprLabel} ${money.format(calc.taxAmount)}',
                      ),
                      const Divider(height: AppSpacing.lg),
                      _SummaryRow(
                        label: l10n.totalLabel,
                        value: '${l10n.nprLabel} ${money.format(calc.total)}',
                        highlight: true,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _issuing ? null : _saveDraftOnly,
                    child: Text(l10n.invoiceSaveDraft),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _issuing ? null : _saveAndIssue,
                    child: Text(
                      _issuing
                          ? l10n.invoiceIssuing
                          : l10n.invoiceIssueAction,
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final storeId = await ref.read(preferencesProvider).getActiveStoreId();
    if (storeId == null || storeId.isEmpty) {
      setState(() {
        _error = l10n.invoiceNoActiveStore;
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
        _error = l10n.invoiceAddAtLeastOneItem;
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
          dueDateAd: _dueDateAd,
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

  Future<void> _pickDueDate(BuildContext context) async {
    final calendarAsync = ref.read(calendarAdapterProvider);
    final calendar =
        calendarAsync is AsyncData<CalendarAdapter>
            ? calendarAsync.value
            : CalendarAdapter(
              calendarMode: 'AD',
              localeCode: Localizations.localeOf(context).languageCode,
            );
    if (calendar.isBsMode) {
      await _pickBsDueDate(context, calendar);
      return;
    }

    final now = DateTime.now();
    final initial =
        _dueDateAd ?? DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueDateAd = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickBsDueDate(
    BuildContext context,
    CalendarAdapter calendar,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final initialAd =
        _dueDateAd ?? DateTime.now().add(const Duration(days: 7));
    final initialBs = calendar.adToBsDate(initialAd);
    final yearCtrl = TextEditingController(text: initialBs.year.toString());
    final monthCtrl = TextEditingController(text: initialBs.month.toString());
    final dayCtrl = TextEditingController(text: initialBs.day.toString());
    String? dialogError;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.invoicePickBsDateTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.yearLabel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: monthCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.monthLabel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: dayCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.dayLabel),
                        ),
                      ),
                    ],
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dialogError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final year = int.tryParse(yearCtrl.text.trim());
                    final month = int.tryParse(monthCtrl.text.trim());
                    final day = int.tryParse(dayCtrl.text.trim());
                    if (year == null || month == null || day == null) {
                      setDialogState(() => dialogError = l10n.invalidBsDate);
                      return;
                    }
                    final ad = calendar.bsToAdDate(
                      year: year,
                      month: month,
                      day: day,
                    );
                    if (ad == null) {
                      setDialogState(() => dialogError = l10n.invalidBsDate);
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      DateTime(ad.year, ad.month, ad.day),
                    );
                  },
                  child: Text(
                    MaterialLocalizations.of(dialogContext).okButtonLabel,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    yearCtrl.dispose();
    monthCtrl.dispose();
    dayCtrl.dispose();

    if (picked == null || !mounted) return;
    setState(() {
      _dueDateAd = DateTime(picked.year, picked.month, picked.day);
    });
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: highlight ? AppColors.primary : AppColors.label,
      fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
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
    final l10n = AppLocalizations.of(context)!;
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
                      labelText: l10n.invoiceLineItemName,
                    ),
                    onChanged: (_) => _emit(),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? l10n.requiredLabel
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
                labelText: l10n.invoiceProductIdOptional,
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
                      labelText: l10n.qtyLabel,
                    ),
                    onChanged: (_) => _emit(),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) {
                        return l10n.invoiceQtyPositive;
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
                      labelText: l10n.unitLabel,
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
                      labelText: l10n.rateLabel,
                    ),
                    onChanged: (_) => _emit(),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) {
                        return l10n.invalidLabel;
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
