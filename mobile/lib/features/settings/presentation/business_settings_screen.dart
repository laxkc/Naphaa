import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(_hydrate);
  }

  static const _currencies = ['NPR', 'USD', 'INR'];
  static const _businessTypes = [
    'Retail',
    'Grocery',
    'Restaurant',
    'Pharmacy',
    'Electronics',
    'Other',
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
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);
    if (!_loaded) {
      profileAsync.whenOrNull(
        data: (p) {
          if (!_loaded) {
            if (p.storeName?.trim().isNotEmpty ?? false) {
              _nameCtl.text = p.storeName!.trim();
            }
            if (p.storeAddress?.trim().isNotEmpty ?? false) {
              _addressCtl.text = p.storeAddress!.trim();
            }
            if (p.storePhone?.trim().isNotEmpty ?? false) {
              _phoneCtl.text = p.storePhone!.trim();
            }
            if (p.businessType?.trim().isNotEmpty ?? false) {
              _businessType = p.businessType!.trim();
            }
            if (p.currency?.trim().isNotEmpty ?? false) {
              _currency = p.currency!.trim();
            }
            _loaded = true;
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.businessSettings),
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
                decoration: InputDecoration(
                  labelText: l10n.businessSettingsNameLabel,
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n.businessSettingsNameRequired
                            : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneCtl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.businessSettingsPhoneOptionalLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressCtl,
                decoration: InputDecoration(
                  labelText: l10n.businessSettingsAddressOptionalLabel,
                  hintText: l10n.businessSettingsAddressHint,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.currencyLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children:
                    _currencies.map((c) {
                      return ChoiceChip(
                        label: Text(c),
                        selected: _currency == c,
                        onSelected: (_) => setState(() => _currency = c),
                        showCheckmark: false,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color:
                              _currency == c ? Colors.white : AppColors.label,
                          fontWeight:
                              _currency == c
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color:
                              _currency == c
                                  ? AppColors.primary
                                  : AppColors.border,
                          width: 1,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.businessTypeLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children:
                    _businessTypes.map((t) {
                      return ChoiceChip(
                        label: Text(switch (t) {
                          'Retail' => l10n.businessTypeRetail,
                          'Grocery' => l10n.businessTypeGrocery,
                          'Restaurant' => l10n.businessTypeRestaurant,
                          'Pharmacy' => l10n.businessTypePharmacy,
                          'Electronics' => l10n.businessTypeElectronics,
                          _ => l10n.otherLabel,
                        }),
                        selected: _businessType == t,
                        onSelected: (_) => setState(() => _businessType = t),
                        showCheckmark: false,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color:
                              _businessType == t
                                  ? Colors.white
                                  : AppColors.label,
                          fontWeight:
                              _businessType == t
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color:
                              _businessType == t
                                  ? AppColors.primary
                                  : AppColors.border,
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
                  child:
                      _saving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final locale = ref.read(localeControllerProvider).languageCode;
      await ref.read(sessionServiceProvider).ensureReady(localeCode: locale);
      final gateway = ref.read(backendGatewayProvider);
      final store = await gateway.getStoreMe();
      final storeId = store['id']?.toString();
      if (storeId == null || storeId.isEmpty) {
        throw Exception('Store not found');
      }
      await gateway.updateStore(
        storeId: storeId,
        name: _nameCtl.text.trim(),
        address: _addressCtl.text.trim(),
        phone: _phoneCtl.text.trim(),
        businessType: _businessType,
        currency: _currency,
      );

      // Keep local billing snapshots aligned with server-backed store settings.
      await ref
          .read(preferencesProvider)
          .setBillingSettings(
            businessName: _nameCtl.text.trim(),
            businessAddress: _addressCtl.text.trim(),
            businessPhone: _phoneCtl.text.trim(),
            currencyCode: _currency,
          );

      ref.invalidate(profileProvider);
      ref.invalidate(businessMetricsProvider);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.businessSettingsSaved,
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = l10n.businessSettingsSaveFailed;
      });
    }
  }

  Future<void> _hydrate() async {
    if (!mounted) return;
    try {
      final locale = ref.read(localeControllerProvider).languageCode;
      await ref.read(sessionServiceProvider).ensureReady(localeCode: locale);
      final gateway = ref.read(backendGatewayProvider);
      final prefs = ref.read(preferencesProvider);

      final profile = await gateway.getAuthMe();
      Map<String, dynamic>? storeFallback;
      final billing = await prefs.getBillingSettings();
      final missingAnyStoreField =
          (profile['store_name']?.toString().trim().isEmpty ?? true) ||
          (profile['store_address']?.toString().trim().isEmpty ?? true) ||
          (profile['store_phone']?.toString().trim().isEmpty ?? true) ||
          (profile['business_type']?.toString().trim().isEmpty ?? true) ||
          (profile['currency']?.toString().trim().isEmpty ?? true);
      if (missingAnyStoreField) {
        storeFallback = await gateway.getStoreMe();
      }

      if (!mounted) return;
      setState(() {
        final fallbackName = storeFallback?['name']?.toString().trim();
        final fallbackAddress = storeFallback?['address']?.toString().trim();
        final fallbackPhone = storeFallback?['phone']?.toString().trim();
        final fallbackBusinessType =
            storeFallback?['business_type']?.toString().trim();
        final fallbackCurrency = storeFallback?['currency']?.toString().trim();

        final profileName = profile['store_name']?.toString().trim();
        final profileAddress = profile['store_address']?.toString().trim();
        final profilePhone = profile['store_phone']?.toString().trim();
        final profileBusinessType = profile['business_type']?.toString().trim();
        final profileCurrency = profile['currency']?.toString().trim();

        _nameCtl.text =
            (profileName?.isNotEmpty ?? false)
                ? profileName!
                : ((fallbackName?.isNotEmpty ?? false)
                    ? fallbackName!
                    : _nameCtl.text);
        _addressCtl.text =
            (profileAddress?.isNotEmpty ?? false)
                ? profileAddress!
                : ((fallbackAddress?.isNotEmpty ?? false)
                    ? fallbackAddress!
                    : '');
        _phoneCtl.text =
            (profilePhone?.isNotEmpty ?? false)
                ? profilePhone!
                : ((fallbackPhone?.isNotEmpty ?? false) ? fallbackPhone! : '');
        _businessType =
            (profileBusinessType?.isNotEmpty ?? false)
                ? profileBusinessType!
                : ((fallbackBusinessType?.isNotEmpty ?? false)
                    ? fallbackBusinessType!
                    : _businessType);
        _currency =
            (profileCurrency?.isNotEmpty ?? false)
                ? profileCurrency!
                : ((fallbackCurrency?.isNotEmpty ?? false)
                    ? fallbackCurrency!
                    : _currency);
        if (_addressCtl.text.isEmpty) {
          _addressCtl.text =
              (billing['business_address']?.toString() ?? '').trim();
        }
        if (_phoneCtl.text.isEmpty) {
          _phoneCtl.text = (billing['business_phone']?.toString() ?? '').trim();
        }
        _loaded = true;
      });
    } catch (_) {
      // Fallback to whatever profile/prefs already populated.
      if (!mounted) return;
      setState(() {
        _loaded = true;
      });
    }
  }
}
