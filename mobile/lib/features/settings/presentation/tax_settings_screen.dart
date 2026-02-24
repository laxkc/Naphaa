import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/context_i18n.dart';
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
          _vatRateCtl.text =
              (settings['rate'] as num?)?.toString() ?? '13';
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Tax Settings', 'कर सेटिङ')),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            Text(context.tr('Enable VAT', 'VAT सक्षम गर्नुहोस्'),
                                style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              context.tr(
                                'Apply VAT to sales automatically',
                                'बिक्रीमा VAT स्वतः लागू गर्नुहोस्',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
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
                          (states) => states.contains(WidgetState.selected)
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
            TextFormField(
              controller: _panCtl,
              decoration: const InputDecoration(
                labelText: 'PAN Number (optional)',
                hintText: '9-digit PAN',
              ),
              maxLength: 9,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _vatRateCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'VAT Rate (%)',
                hintText: '13',
                suffixText: '%',
              ),
              enabled: _vatEnabled,
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
                    : Text(context.tr('Save Tax Settings', 'कर सेटिङ सेभ गर्नुहोस्')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final prefs = ref.read(preferencesProvider);
      await prefs.setTaxSettings(
        enabled: _vatEnabled,
        name: _panCtl.text.trim().isEmpty ? 'VAT' : _panCtl.text.trim(),
        rate: double.tryParse(_vatRateCtl.text.trim()) ?? 13.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Tax settings saved', 'कर सेटिङ सेभ भयो'))),
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
