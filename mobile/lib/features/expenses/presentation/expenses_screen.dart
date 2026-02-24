import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

// ─── category meta ────────────────────────────────────────────────────────────

class _Cat {
  const _Cat(this.key, this.label, this.icon, this.color);
  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

const _categories = [
  _Cat('RENT',      'Rent',      Icons.home_outlined,        Color(0xFF6A1B9A)),
  _Cat('TRANSPORT', 'Transport', Icons.directions_car_outlined, Color(0xFF1565C0)),
  _Cat('UTILITIES', 'Utilities', Icons.bolt_outlined,         Color(0xFFEF6C00)),
  _Cat('SALARY',    'Salary',    Icons.badge_outlined,        Color(0xFF00695C)),
  _Cat('OTHER',     'Other',     Icons.category_outlined,     Color(0xFF546E7A)),
];

_Cat _catFor(String key) =>
    _categories.firstWhere((c) => c.key == key,
        orElse: () => _categories.last);

// ─── screen ───────────────────────────────────────────────────────────────────

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n     = AppLocalizations.of(context)!;
    final expenses = ref.watch(expensesListProvider);

    return Column(
      children: [
        // ── header ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.trackExpenses,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              FilledButton.icon(
                onPressed: () => _showExpenseSheet(context, ref, l10n),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.addExpense),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ],
          ),
        ),

        // ── list ─────────────────────────────────────────────────────────
        Expanded(
          child: expenses.when(
            loading: () => ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => const SkeletonListTile(),
            ),
            error: (_, __) => ErrorRetry(
              onRetry: () => ref.invalidate(expensesListProvider),
              message: 'Failed to load expenses',
            ),
            data: (items) => items.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.trackExpenses,
                    subtitle: 'Tap "Add Expense" to record your first expense.',
                    action: l10n.addExpense,
                    onAction: () => _showExpenseSheet(context, ref, l10n),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(
                        indent: 72, endIndent: AppSpacing.lg, height: 0),
                    itemBuilder: (_, i) {
                      final e   = items[i];
                      final cat = _catFor(e.category);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs),
                        leading: CategoryBadge(icon: cat.icon, color: cat.color),
                        title: Text(
                          cat.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.label,
                          ),
                        ),
                        subtitle: e.note != null
                            ? Text(e.note!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted))
                            : null,
                        trailing: Text(
                          'Rs ${e.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cat.color,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showExpenseSheet(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showAppBottomSheet(context, child: ExpenseFormSheet(ref: ref, l10n: l10n));
  }
}

// ─── add expense bottom sheet ─────────────────────────────────────────────────

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({super.key, required this.ref, required this.l10n});
  final WidgetRef ref;
  final AppLocalizations l10n;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseFormSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtl  = TextEditingController();
  final _noteCtl    = TextEditingController();
  _Cat _category    = _categories[1]; // TRANSPORT default
  bool _saving = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(l10n.addExpense),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // category chips
                Text('Category',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: _categories.map((c) {
                    final selected = c.key == _category.key;
                    return ChoiceChip(
                      avatar: Icon(c.icon,
                          size: 15,
                          color: selected ? c.color : AppColors.muted),
                      label: Text(c.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: c.color.withAlpha(28),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected ? c.color : AppColors.muted,
                      ),
                      side: BorderSide(
                        color: selected ? c.color : AppColors.border,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // amount
                TextFormField(
                  controller: _amountCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    prefixText: 'Rs ',
                  ),
                  validator: (v) {
                    final a = double.tryParse(v ?? '');
                    if (a == null || a <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // note
                TextFormField(
                  controller: _noteCtl,
                  decoration: InputDecoration(labelText: '${l10n.note} (optional)'),
                ),
                const SizedBox(height: AppSpacing.xxl),

                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.ref.read(expensesRepositoryProvider).addExpense(
            category: _category.key,
            amount: double.parse(_amountCtl.text.trim()),
            note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
          );
      final localeCode =
          widget.ref.read(localeControllerProvider).languageCode;
      await widget.ref
          .read(syncManagerProvider)
          .processPendingSync(localeCode: localeCode);
      widget.ref
        ..invalidate(expensesListProvider)
        ..invalidate(dashboardSummaryProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
