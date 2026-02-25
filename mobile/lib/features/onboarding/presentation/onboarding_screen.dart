import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _pageController = PageController();

  // Step 1
  String _currency = 'NPR';
  String _businessType = 'Grocery';

  // Step 2
  String _unit = 'piece';
  bool _taxEnabled = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 1) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    final prefs = ref.read(preferencesProvider);
    await prefs.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.onboardingSetupStoreTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.onboardingStepOfTotal(_step + 1, 2),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _complete,
                    child: Text(l10n.skipLabel),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                children: List.generate(2, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 1 ? AppSpacing.sm : 0),
                      decoration: BoxDecoration(
                        color:
                            i <= _step ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.h),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepOne(
                    currency: _currency,
                    businessType: _businessType,
                    onCurrencyChanged: (v) => setState(() => _currency = v),
                    onBusinessTypeChanged:
                        (v) => setState(() => _businessType = v),
                  ),
                  _StepTwo(
                    unit: _unit,
                    taxEnabled: _taxEnabled,
                    onUnitChanged: (v) => setState(() => _unit = v),
                    onTaxChanged: (v) => setState(() => _taxEnabled = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _step < 1
                        ? l10n.nextLabel
                        : l10n.onboardingDoneOpenStore,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepOne extends StatelessWidget {
  const _StepOne({
    required this.currency,
    required this.businessType,
    required this.onCurrencyChanged,
    required this.onBusinessTypeChanged,
  });
  final String currency;
  final String businessType;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onBusinessTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.currencyLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children:
                ['NPR', 'USD', 'INR'].map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: currency == c,
                    onSelected: (_) => onCurrencyChanged(c),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: currency == c ? Colors.white : AppColors.label,
                      fontWeight:
                          currency == c ? FontWeight.w700 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color:
                          currency == c ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSpacing.h),
          Text(
            l10n.businessTypeLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children:
                [
                  'Grocery',
                  'General Store',
                  'Pharmacy',
                  'Electronics',
                  'Other',
                ].map((t) {
                  final label = switch (t) {
                    'Grocery' => l10n.businessTypeGrocery,
                    'General Store' => l10n.onboardingBusinessTypeGeneralStore,
                    'Pharmacy' => l10n.businessTypePharmacy,
                    'Electronics' => l10n.businessTypeElectronics,
                    _ => l10n.otherLabel,
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: businessType == t,
                    onSelected: (_) => onBusinessTypeChanged(t),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: businessType == t ? Colors.white : AppColors.label,
                      fontWeight:
                          businessType == t ? FontWeight.w700 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color:
                          businessType == t
                              ? AppColors.primary
                              : AppColors.border,
                      width: 1,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepTwo extends StatelessWidget {
  const _StepTwo({
    required this.unit,
    required this.taxEnabled,
    required this.onUnitChanged,
    required this.onTaxChanged,
  });
  final String unit;
  final bool taxEnabled;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<bool> onTaxChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingDefaultMeasurementUnit,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.onboardingUnitOverrideHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children:
                ['piece', 'kg', 'litre', 'packet'].map((u) {
                  final unitLabel = switch (u) {
                    'piece' => l10n.onboardingUnitPiece,
                    'kg' => l10n.onboardingUnitKg,
                    'litre' => l10n.onboardingUnitLitre,
                    _ => l10n.onboardingUnitPacket,
                  };
                  return ChoiceChip(
                    label: Text(unitLabel),
                    selected: unit == u,
                    onSelected: (_) => onUnitChanged(u),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: unit == u ? Colors.white : AppColors.label,
                      fontWeight: unit == u ? FontWeight.w700 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: unit == u ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSpacing.h),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: Text(
                l10n.onboardingEnableTaxVat,
              ),
              subtitle: Text(
                taxEnabled
                    ? l10n.onboardingTaxWillApply
                    : l10n.onboardingNoTaxApplied,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              value: taxEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: onTaxChanged,
            ),
          ),
        ],
      ),
    );
  }
}
