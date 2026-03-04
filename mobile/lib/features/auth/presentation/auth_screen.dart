import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/config/app_config.dart';
import 'package:sme_digital/constants/branding.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/auth_state.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _phoneCtl = TextEditingController();
  final _otpCtl = TextEditingController();
  bool _isRoutingAfterAuth = false;

  @override
  void dispose() {
    _phoneCtl.dispose();
    _otpCtl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return l10n.fieldRequired;
    if (!phone.startsWith('9') || phone.length != 10) return l10n.invalidPhone;
    return null;
  }

  String? _validateOtp(String? value, AppLocalizations l10n) {
    final otp = (value ?? '').trim();
    if (otp.isEmpty) return l10n.fieldRequired;
    if (otp.length < 4 || otp.length > 8) {
      return l10n.authOtpInvalidCode;
    }
    return null;
  }

  Future<void> _submitPhone() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).requestOtp(
          phone: _phoneCtl.text.trim(),
        );
    if (!mounted) return;
    final next = ref.read(authControllerProvider);
    if (next.error == null && next.otpRequested) {
      _otpCtl.clear();
      FocusScope.of(context).requestFocus(FocusNode());
    } else if (next.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.error ?? l10n.somethingWentWrong)),
      );
    }
  }

  Future<void> _submitOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).verifyOtp(
          phone: _phoneCtl.text.trim(),
          otp: _otpCtl.text.trim(),
        );
    if (!mounted) return;
    final next = ref.read(authControllerProvider);
    if (next.error != null && !next.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.error ?? l10n.somethingWentWrong)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!next.authenticated) {
        _isRoutingAfterAuth = false;
        return;
      }
      if (_isRoutingAfterAuth || !mounted) return;
      _isRoutingAfterAuth = true;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: auth.otpRequested
                        ? _OtpStep(
                            key: const ValueKey('otp-step'),
                            l10n: l10n,
                            auth: auth,
                            otpFormKey: _otpFormKey,
                            phone: _phoneCtl.text.trim(),
                            otpCtl: _otpCtl,
                            validateOtp: (value) => _validateOtp(value, l10n),
                            onVerify: _submitOtp,
                            onResend: _submitPhone,
                            onChangePhone: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .resetOtpFlow(phone: _phoneCtl.text.trim());
                            },
                          )
                        : _PhoneStep(
                            key: const ValueKey('phone-step'),
                            l10n: l10n,
                            auth: auth,
                            phoneFormKey: _phoneFormKey,
                            phoneCtl: _phoneCtl,
                            validatePhone: (value) =>
                                _validatePhone(value, l10n),
                            onSubmit: _submitPhone,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.l10n,
    required this.auth,
    required this.phoneFormKey,
    required this.phoneCtl,
    required this.validatePhone,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final AuthState auth;
  final GlobalKey<FormState> phoneFormKey;
  final TextEditingController phoneCtl;
  final String? Function(String?) validatePhone;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: phoneFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandHeader(
            title: l10n.authOtpTitle,
            subtitle: l10n.authOtpSubtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: phoneCtl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.phone,
              hintText: '98XXXXXXXX',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: validatePhone,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.authOtpAutoCreateBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            InlineBanner(type: BannerType.error, message: auth.error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: auth.loading ? null : onSubmit,
              child: auth.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.authSendOtp),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.l10n,
    required this.auth,
    required this.otpFormKey,
    required this.phone,
    required this.otpCtl,
    required this.validateOtp,
    required this.onVerify,
    required this.onResend,
    required this.onChangePhone,
  });

  final AppLocalizations l10n;
  final AuthState auth;
  final GlobalKey<FormState> otpFormKey;
  final String phone;
  final TextEditingController otpCtl;
  final String? Function(String?) validateOtp;
  final Future<void> Function() onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onChangePhone;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: otpFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandHeader(
            title: l10n.authVerifyOtpTitle,
            subtitle: l10n.authOtpSentTo(phone),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: otpCtl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.authOtpCodeLabel,
              hintText: '123456',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
            ),
            validator: validateOtp,
            onFieldSubmitted: (_) => onVerify(),
          ),
          if (auth.debugOtpCode != null) ...[
            const SizedBox(height: AppSpacing.md),
            InlineBanner(
              type: BannerType.info,
              message: l10n.authOtpDebugCode(auth.debugOtpCode!),
            ),
          ],
          if (auth.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            InlineBanner(type: BannerType.error, message: auth.error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: auth.loading ? null : onVerify,
              child: auth.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.authVerifyOtp),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: auth.loading ? null : onResend,
                  child: Text(l10n.authResendOtp),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextButton(
                  onPressed: auth.loading ? null : onChangePhone,
                  child: Text(l10n.authChangePhone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.asset(Branding.logoAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConfig.tagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
