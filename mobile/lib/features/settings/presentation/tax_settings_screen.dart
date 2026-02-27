import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class TaxSettingsScreen extends ConsumerStatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  ConsumerState<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends ConsumerState<TaxSettingsScreen> {
  final _panCtl = TextEditingController();
  final _vatRateCtl = TextEditingController(text: '13');
  bool _vatEnabled = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = ref.read(preferencesProvider);
      final settings = await prefs.getTaxSettings();
      if (mounted) {
        setState(() {
          _vatEnabled = settings['enabled'] as bool? ?? false;
          _panCtl.text = settings['name'] as String? ?? '';
          _vatRateCtl.text = (settings['rate'] as num?)?.toString() ?? '13';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _panCtl.dispose();
    _vatRateCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.taxSettingsTitle),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                      l10n.settingsTaxSettingsSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.taxSettingsEnableVat,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              l10n.taxSettingsEnableVatSubtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _vatEnabled,
                        onChanged: (v) => setState(() => _vatEnabled = v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: AppColors.border,
                        trackOutlineColor: WidgetStateProperty.resolveWith(
                          (states) =>
                              states.contains(WidgetState.selected)
                                  ? AppColors.primary
                                  : AppColors.border,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _panCtl,
                    decoration: InputDecoration(
                      labelText: l10n.taxSettingsPanOptionalLabel,
                      hintText: l10n.taxSettingsPanHint,
                    ),
                    maxLength: 9,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _vatRateCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.taxSettingsVatRateLabel,
                      hintText: '13',
                      suffixText: '%',
                    ),
                    enabled: _vatEnabled,
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
                icon:
                    _saving
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save_outlined, size: 18),
                label:
                    _saving
                        ? Text(l10n.loadingLabel)
                        : Text(
                          l10n.taxSettingsSaveAction,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final prefs = ref.read(preferencesProvider);
      await prefs.setTaxSettings(
        enabled: _vatEnabled,
        name:
            _panCtl.text.trim().isEmpty
                ? l10n.vatLabel
                : _panCtl.text.trim(),
        rate: double.tryParse(_vatRateCtl.text.trim()) ?? 13.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.taxSettingsSaved),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = l10n.taxSettingsSaveFailed;
      });
    }
  }
}
