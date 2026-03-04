import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class BillingSettingsScreen extends ConsumerStatefulWidget {
  const BillingSettingsScreen({super.key});

  @override
  ConsumerState<BillingSettingsScreen> createState() =>
      _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends ConsumerState<BillingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoicePrefixCtl = TextEditingController();
  final _termsCtl = TextEditingController();
  final _footerCtl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _language = 'ne';
  String _fiscalCalendar = 'BS';
  String _taxMode = 'exclusive';
  String _currencyCode = 'NPR';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _invoicePrefixCtl.dispose();
    _termsCtl.dispose();
    _footerCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.billingSettingsTitle),
        backgroundColor: AppColors.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              l10n.billingSettingsSubtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _invoicePrefixCtl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: l10n.billingSettingsInvoicePrefixLabel,
                              hintText: 'INV',
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) {
                                return l10n.billingSettingsInvoicePrefixRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            initialValue: _language,
                            decoration: InputDecoration(
                              labelText: l10n.language,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'ne',
                                child: Text(l10n.nepaliLabel),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(l10n.englishLabel),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _language = value);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            initialValue: _fiscalCalendar,
                            decoration: InputDecoration(
                              labelText: l10n.calendarModeLabel,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'BS',
                                child: Text(l10n.calendarBsLabel),
                              ),
                              DropdownMenuItem(
                                value: 'AD',
                                child: Text(l10n.calendarAdLabel),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _fiscalCalendar = value);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            initialValue: _taxMode,
                            decoration: InputDecoration(
                              labelText: l10n.billingSettingsTaxModeLabel,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'exclusive',
                                child: Text(
                                  l10n.billingSettingsTaxModeExclusive,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'inclusive',
                                child: Text(
                                  l10n.billingSettingsTaxModeInclusive,
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _taxMode = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _termsCtl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText:
                                  l10n.billingSettingsTermsDefaultLabel,
                              hintText:
                                  l10n.billingSettingsTermsDefaultHint,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _footerCtl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText:
                                  l10n.billingSettingsFooterDefaultLabel,
                              hintText:
                                  l10n.billingSettingsFooterDefaultHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      InlineBanner(type: BannerType.error, message: _error!),
                    ],
                    const SizedBox(height: AppSpacing.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: _saving
                            ? Text(l10n.loadingLabel)
                            : Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _load() async {
    final prefs = ref.read(preferencesProvider);
    final settings = await prefs.getBillingSettings();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invoicePrefixCtl.text =
          (settings['invoice_prefix']?.toString() ?? 'INV').trim();
      _termsCtl.text =
          (settings['invoice_terms_default']?.toString() ?? '').trim();
      _footerCtl.text =
          (settings['invoice_footer_default']?.toString() ?? '').trim();
      _language = (settings['language']?.toString() ?? 'ne').trim();
      _fiscalCalendar =
          (settings['fiscal_calendar']?.toString() ?? 'BS').trim().toUpperCase();
      _taxMode = (settings['tax_mode']?.toString() ?? 'exclusive').trim();
      _currencyCode = (settings['currency_code']?.toString() ?? 'NPR').trim();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(preferencesProvider).setBillingSettings(
            language: _language,
            currencyCode: _currencyCode,
            fiscalCalendar: _fiscalCalendar,
            taxMode: _taxMode,
            invoicePrefix: _invoicePrefixCtl.text.trim().toUpperCase(),
            invoiceTermsDefault: _termsCtl.text.trim(),
            invoiceFooterDefault: _footerCtl.text.trim(),
          );
      ref.invalidate(invoicesListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.billingSettingsSaved)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.billingSettingsSaveFailed;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
  }
}
