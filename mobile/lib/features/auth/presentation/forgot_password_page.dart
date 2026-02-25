import 'package:flutter/material.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../shared/widgets/ui_kit.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.authForgotResetTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.authForgotResetBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.h),
            if (_submitted) ...[
              InlineBanner(
                type: BannerType.success,
                message: l10n.authForgotSuccessBanner,
              ),
              const SizedBox(height: AppSpacing.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.authForgotBackToLogin),
                ),
              ),
            ] else ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  hintText: '98XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _phoneController.text.isEmpty
                          ? null
                          : () => setState(() => _submitted = true),
                  child: Text(
                    l10n.authForgotSendResetInstructions,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
