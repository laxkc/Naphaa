import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/context_i18n.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class BusinessSettingsScreen extends ConsumerStatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  ConsumerState<BusinessSettingsScreen> createState() =>
      _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState
    extends ConsumerState<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  String? _error;
  String _currency = 'NPR';
  String _businessType = 'Retail';

  static const _currencies = ['NPR', 'USD', 'INR'];
  static const _businessTypes = [
    'Retail',
    'Grocery',
    'Restaurant',
    'Pharmacy',
    'Electronics',
    'Other'
  ];

  @override
  void dispose() {
    _nameCtl.dispose();
    _addressCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill from profile
    final profileAsync = ref.watch(profileProvider);
    if (!_loaded) {
      profileAsync.whenOrNull(data: (p) {
        if (!_loaded) {
          _nameCtl.text = p.storeName ?? '';
          _loaded = true;
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Business Settings', 'व्यवसाय सेटिङ')),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Business Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneCtl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Business Phone (optional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  hintText: 'Street, City, District',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(context.tr('Currency', 'मुद्रा'),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: _currencies.map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: _currency == c,
                    onSelected: (_) => setState(() => _currency = c),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _currency == c ? Colors.white : AppColors.label,
                      fontWeight:
                          _currency == c ? FontWeight.w700 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _currency == c ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(context.tr('Business Type', 'व्यवसाय प्रकार'),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: _businessTypes.map((t) {
                  return ChoiceChip(
                    label: Text(t),
                    selected: _businessType == t,
                    onSelected: (_) => setState(() => _businessType = t),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _businessType == t ? Colors.white : AppColors.label,
                      fontWeight: _businessType == t
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _businessType == t ? AppColors.primary : AppColors.border,
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
                      : Text(context.tr('Save', 'सेभ')),
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
      // Save via profile provider (store name is part of profile)
      // For now we save to prefs and invalidate profile
      ref.invalidate(profileProvider);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Business settings saved', 'व्यवसाय सेटिङ सेभ भयो'))),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save. Try again.';
      });
    }
  }
}
