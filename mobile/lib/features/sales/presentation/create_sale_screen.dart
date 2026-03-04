import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/l10n/display_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../customers/domain/customer.dart';
import '../../customers/domain/customer_risk_metric.dart';
import '../sales_controller.dart';
import '../domain/sale_models.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: initialName.trim());
    final priceCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.salesQuickAddProductTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.productName),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.sellPriceLabel),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
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
                child: Text(l10n.createLabel),
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
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.salesQuickCreditCustomerTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.customerName),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneOptionalLabel,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
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
                child: Text(l10n.saveCreditSale),
              ),
            ],
          ),
    );
  }

  Future<void> _showCreditCustomerPickerDialog(
    BuildContext context,
    WidgetRef ref,
    SalesController controller,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    List<Customer> customers;
    Map<String, CustomerRiskMetric> riskMap;
    try {
      customers = await ref.read(customersListProvider.future);
      riskMap = await ref.read(customerRiskMetricsProvider.future);
    } catch (_) {
      await _showQuickCreditCustomerDialog(context, ref, controller);
      return;
    }

    final searchCtrl = TextEditingController();
    var query = '';
    try {
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => StatefulBuilder(
              builder: (ctx, setState) {
                final filtered =
                    customers.where((c) {
                      final q = query.trim().toLowerCase();
                      if (q.isEmpty) return true;
                      return c.name.toLowerCase().contains(q) ||
                          (c.phone?.toLowerCase().contains(q) ?? false);
                    }).toList();
                return AlertDialog(
                  title: Text(l10n.salesQuickCreditCustomerTitle),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: l10n.searchProducts,
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() => query = value),
                        ),
                        const SizedBox(height: 10),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No customers found',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const Divider(height: 1, thickness: 0.5),
                              itemBuilder: (_, i) {
                                final customer = filtered[i];
                                final risk = riskMap[customer.id];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(customer.name),
                                  subtitle: Text(
                                    [
                                      if (customer.phone?.isNotEmpty == true)
                                        customer.phone!,
                                      '${l10n.nprLabel} ${customer.balance.toStringAsFixed(2)}',
                                    ].join(' • '),
                                  ),
                                  trailing:
                                      risk == null
                                          ? null
                                          : StatusChip(
                                            label: riskLevelLabel(
                                              context,
                                              risk.riskLevel,
                                              short: true,
                                            ),
                                            color:
                                                risk.riskLevel.toLowerCase() ==
                                                        'red'
                                                    ? AppColors.error
                                                    : risk.riskLevel
                                                            .toLowerCase() ==
                                                        'yellow'
                                                    ? AppColors.warning
                                                    : AppColors.success,
                                          ),
                                  onTap: () async {
                                    final confirmed =
                                        await _confirmCreditRiskForCustomer(
                                          context,
                                          customer: customer,
                                          risk: risk,
                                        );
                                    if (!confirmed) return;
                                    final ok = await controller
                                        .saveCreditSaleForCustomerId(
                                          customer.id,
                                        );
                                    if (ok && ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _showQuickCreditCustomerDialog(
                          context,
                          ref,
                          controller,
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(l10n.addCustomer),
                    ),
                  ],
                );
              },
            ),
      );
    } finally {
      searchCtrl.dispose();
    }
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
          final label = riskLevelLabel(context, level);
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l10n.salesCreditRiskWarningTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.salesCreditRiskExistingCustomerMarked(
                    existing.name,
                    label,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.salesCreditRiskOutstandingNpr(
                    risk.outstandingAmount.toStringAsFixed(2),
                  ),
                ),
                Text(l10n.salesCreditRiskOldestDueDays(risk.oldestDueDays)),
                Text(l10n.salesCreditRiskScore(risk.riskScore.toString())),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: Text(l10n.salesCreditRiskContinueWarning),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.continueLabel),
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

  Future<bool> _confirmCreditRiskForCustomer(
    BuildContext context, {
    required Customer customer,
    CustomerRiskMetric? risk,
  }) async {
    final level = risk?.riskLevel.toLowerCase() ?? '';
    if (level != 'red' && level != 'yellow') return true;
    final color = level == 'red' ? AppColors.error : AppColors.warning;
    final l10n = AppLocalizations.of(context)!;
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.salesCreditRiskWarningTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.salesCreditRiskExistingCustomerMarked(
                    customer.name,
                    riskLevelLabel(context, level),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.salesCreditRiskOutstandingNpr(
                    (risk?.outstandingAmount ?? customer.balance)
                        .toStringAsFixed(2),
                  ),
                ),
                Text(
                  l10n.salesCreditRiskOldestDueDays(risk?.oldestDueDays ?? 0),
                ),
                Text(
                  l10n.salesCreditRiskScore((risk?.riskScore ?? 0).toString()),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: Text(l10n.salesCreditRiskContinueWarning),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
    );
    return shouldProceed ?? false;
  }

  Future<void> _showAdvancedCheckoutDialog(
    BuildContext context,
    SalesController controller, {
    required double totalAmt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final methods = <PaymentMethod>[
      PaymentMethod.cash,
      PaymentMethod.qr,
      PaymentMethod.bank,
      PaymentMethod.wallet,
      PaymentMethod.credit,
    ];
    final selected = <PaymentMethod>{PaymentMethod.cash};
    final amountCtrls = <PaymentMethod, TextEditingController>{
      for (final method in methods)
        method: TextEditingController(
          text: method == PaymentMethod.cash ? totalAmt.toStringAsFixed(2) : '',
        ),
    };
    final customerNameCtrl = TextEditingController();
    final customerPhoneCtrl = TextEditingController();
    String? errorText;

    try {
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => StatefulBuilder(
              builder: (ctx, setState) {
                double parsed(TextEditingController c) =>
                    double.tryParse(c.text.trim()) ?? 0;
                final enteredTotal = selected.fold<double>(
                  0,
                  (sum, m) => sum + parsed(amountCtrls[m]!),
                );

                return AlertDialog(
                  title: Text(l10n.paymentMethodLabelTitle),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              methods.map((method) {
                                final isSelected = selected.contains(method);
                                return FilterChip(
                                  label: Text(
                                    paymentMethodLabel(
                                      context,
                                      paymentMethodToApi(method),
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (value) {
                                    setState(() {
                                      if (value) {
                                        selected.add(method);
                                      } else if (selected.length > 1) {
                                        selected.remove(method);
                                      }
                                      errorText = null;
                                    });
                                  },
                                  showCheckmark: false,
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 12),
                        for (final method in selected) ...[
                          Text(
                            paymentMethodLabel(
                              context,
                              paymentMethodToApi(method),
                            ),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountCtrls[method],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.amount,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() => errorText = null),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (selected.contains(PaymentMethod.credit)) ...[
                          TextField(
                            controller: customerNameCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.customerName,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() => errorText = null),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: customerPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: l10n.phoneOptionalLabel,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          '${l10n.totalLabel}: ${l10n.nprLabel} ${totalAmt.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Entered: ${l10n.nprLabel} ${enteredTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorText!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final payments = <SalePaymentInput>[];
                        for (final method in selected) {
                          final amount = double.tryParse(
                            amountCtrls[method]!.text.trim(),
                          );
                          if (amount == null || amount <= 0) {
                            setState(() => errorText = l10n.enterValidAmount);
                            return;
                          }
                          payments.add(
                            SalePaymentInput(method: method, amount: amount),
                          );
                        }
                        final sum = payments.fold<double>(
                          0,
                          (s, p) => s + p.amount,
                        );
                        if ((sum - totalAmt).abs() > 0.01) {
                          setState(
                            () =>
                                errorText =
                                    'Payment total must equal cart total.',
                          );
                          return;
                        }
                        final ok = await controller.saveSaleWithPayments(
                          payments: payments,
                          customerName:
                              selected.contains(PaymentMethod.credit)
                                  ? customerNameCtrl.text
                                  : null,
                          customerPhone:
                              selected.contains(PaymentMethod.credit)
                                  ? customerPhoneCtrl.text
                                  : null,
                        );
                        if (ok && ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                );
              },
            ),
      );
    } finally {
      for (final c in amountCtrls.values) {
        c.dispose();
      }
      customerNameCtrl.dispose();
      customerPhoneCtrl.dispose();
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
        title: Text(l10n.newSale),
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
                            title: Text(
                              l10n.salesCreateProductQuicklyFor(query),
                            ),
                            subtitle: Text(
                              l10n.salesCreateProductQuicklySubtitle,
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
                () => _showCreditCustomerPickerDialog(context, ref, controller),
            onMore:
                () => _showAdvancedCheckoutDialog(
                  context,
                  controller,
                  totalAmt: totalAmt,
                ),
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
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: AppLocalizations.of(context)!.salesNoProductsYetTitle,
        subtitle: AppLocalizations.of(context)!.salesNoProductsQuickCreateHint,
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
              AppLocalizations.of(context)!.salesNoMatchForQuery(query),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onCreateQuick,
              icon: const Icon(Icons.add_box_outlined),
              label: Text(
                AppLocalizations.of(context)!.salesCreateProductQuicklyCta,
              ),
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
              inCart
                  ? AppColors.primary.withValues(alpha: 0.20)
                  : AppColors.surfaceAlt,
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
        '${formatCurrency(price, localeCode)}  ·  ${AppLocalizations.of(context)!.stock} $stock',
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
    required this.onMore,
  });
  final AppLocalizations l10n;
  final int totalQty;
  final double totalAmt;
  final String localeCode;
  final bool loading;
  final VoidCallback onCash;
  final VoidCallback onCredit;
  final VoidCallback onMore;

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
                  l10n.salesCartItemsCount(totalQty),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const Spacer(),
                Text(
                  formatCurrency(totalAmt, localeCode),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    backgroundColor: AppColors.surfaceAlt,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonal(
                onPressed: loading || totalQty == 0 ? null : onMore,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(52, 46),
                  backgroundColor: AppColors.surfaceAlt,
                  foregroundColor: AppColors.primary,
                ),
                child: const Icon(Icons.tune_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
