import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../domain/auth_state.dart';
import 'forgot_password_page.dart';

// ─── palette ──────────────────────────────────────────────────────────────────
const _primary   = Color(0xFF00695C);
const _bg        = Color(0xFFF5F7F6);
const _surface   = Colors.white;
const _label     = Color(0xFF0D1F1C);
const _muted     = Color(0xFF6B7774);
const _border    = Color(0xFFDDE3E1);
const _errBg     = Color(0xFFFDEDED);
const _errBdr    = Color(0xFFF5C6C6);
const _errText   = Color(0xFFB71C1C);

// ─── root ─────────────────────────────────────────────────────────────────────

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialShowRegister = false});
  final bool initialShowRegister;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isSignup = widget.initialShowRegister;
  bool _isRoutingAfterAuth = false;

  final _loginKey  = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();
  final _bizCtl    = TextEditingController();
  final _phoneCtl  = TextEditingController();
  final _passCtl   = TextEditingController();

  @override
  void dispose() {
    _bizCtl.dispose();
    _phoneCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  // validators ────────────────────────────────────────────────────────────────
  String? _vBiz(String? v, AppLocalizations l) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return l.fieldRequired;
    if (s.length < 3) return l.businessNameTooShort;
    return null;
  }

  String? _vPhone(String? v, AppLocalizations l) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return l.fieldRequired;
    if (!s.startsWith('9') || s.length != 10) return l.invalidPhone;
    return null;
  }

  String? _vPass(String? v, AppLocalizations l) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return l.fieldRequired;
    if (s.length < 8) return l.passwordMinLength;
    return null;
  }

  // actions ───────────────────────────────────────────────────────────────────
  Future<void> _login(AppLocalizations l) async {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).login(
          phone: _phoneCtl.text.trim(),
          password: _passCtl.text.trim(),
        );
  }

  Future<void> _signup(AppLocalizations l) async {
    if (!(_signupKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).signup(
          businessName: _bizCtl.text.trim(),
          phone: _phoneCtl.text.trim(),
          password: _passCtl.text.trim(),
        );
  }

  void _forgotPassword(BuildContext ctx, AppLocalizations l) {
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l    = AppLocalizations.of(context)!;
    final auth = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (!next.authenticated) {
        _isRoutingAfterAuth = false;
        return;
      }
      if (_isRoutingAfterAuth || !mounted) return;
      _isRoutingAfterAuth = true;

      final onboardingComplete =
          await ref.read(preferencesProvider).getOnboardingComplete();
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              onboardingComplete ? const AppShell() : const OnboardingScreen(),
        ),
        (route) => false,
      );
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve:  Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(_isSignup ? 1.0 : -1.0, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _isSignup
                    ? _SignupForm(
                        key: const ValueKey('signup'),
                        l: l, auth: auth,
                        formKey: _signupKey,
                        bizCtl: _bizCtl,
                        phoneCtl: _phoneCtl,
                        passCtl: _passCtl,
                        vBiz:   (v) => _vBiz(v, l),
                        vPhone: (v) => _vPhone(v, l),
                        vPass:  (v) => _vPass(v, l),
                        onBack:        () => setState(() => _isSignup = false),
                        onSubmit:      () => _signup(l),
                        onSwitchLogin: () => setState(() => _isSignup = false),
                      )
                    : _LoginForm(
                        key: const ValueKey('login'),
                        l: l, auth: auth,
                        formKey: _loginKey,
                        phoneCtl: _phoneCtl,
                        passCtl:  _passCtl,
                        vPhone: (v) => _vPhone(v, l),
                        vPass:  (v) => _vPass(v, l),
                        onSubmit:        () => _login(l),
                        onForgotPw:      () => _forgotPassword(context, l),
                        onSwitchSignup:  () => setState(() => _isSignup = true),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── login form ───────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({
    super.key,
    required this.l,
    required this.auth,
    required this.formKey,
    required this.phoneCtl,
    required this.passCtl,
    required this.vPhone,
    required this.vPass,
    required this.onSubmit,
    required this.onForgotPw,
    required this.onSwitchSignup,
  });

  final AppLocalizations l;
  final AuthState auth;
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtl;
  final TextEditingController passCtl;
  final String? Function(String?) vPhone;
  final String? Function(String?) vPass;
  final Future<void> Function() onSubmit;
  final VoidCallback onForgotPw;
  final VoidCallback onSwitchSignup;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Brand(),
            const SizedBox(height: 48),

            Text(l.welcomeBack, style: _headStyle(context)),
            const SizedBox(height: 6),
            Text(l.signInToContinue,
                style: const TextStyle(fontSize: 14, color: _muted)),
            const SizedBox(height: 36),

            _Lbl(l.phone),
            const SizedBox(height: 7),
            TextFormField(
              key: const Key('auth_phone'),
              controller: widget.phoneCtl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: _inputStyle,
              decoration: _inputDec(
                  hint: '98XXXXXXXX', icon: Icons.phone_outlined),
              validator: widget.vPhone,
            ),
            const SizedBox(height: 18),

            _Lbl(l.password),
            const SizedBox(height: 7),
            TextFormField(
              key: const Key('auth_password'),
              controller: widget.passCtl,
              obscureText: _hide,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => widget.onSubmit(),
              style: _inputStyle,
              decoration: _inputDec(
                hint: l.passwordHint,
                icon: Icons.lock_outline_rounded,
                eye: _Eye(
                  hide: _hide,
                  onTap: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: widget.vPass,
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPw,
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                ),
                child: Text(l.forgotPassword),
              ),
            ),

            if (widget.auth.error != null) ...[
              _ErrBanner(widget.auth.error!),
              const SizedBox(height: 14),
            ],

            _Btn(
              label: l.signIn,
              loading: widget.auth.loading,
              onPressed: widget.onSubmit,
            ),
            const SizedBox(height: 32),
            _Switch(
              question: l.noAccount,
              action: l.signup,
              onTap: widget.onSwitchSignup,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── signup form ──────────────────────────────────────────────────────────────

class _SignupForm extends StatefulWidget {
  const _SignupForm({
    super.key,
    required this.l,
    required this.auth,
    required this.formKey,
    required this.bizCtl,
    required this.phoneCtl,
    required this.passCtl,
    required this.vBiz,
    required this.vPhone,
    required this.vPass,
    required this.onBack,
    required this.onSubmit,
    required this.onSwitchLogin,
  });

  final AppLocalizations l;
  final AuthState auth;
  final GlobalKey<FormState> formKey;
  final TextEditingController bizCtl;
  final TextEditingController phoneCtl;
  final TextEditingController passCtl;
  final String? Function(String?) vBiz;
  final String? Function(String?) vPhone;
  final String? Function(String?) vPass;
  final VoidCallback onBack;
  final Future<void> Function() onSubmit;
  final VoidCallback onSwitchLogin;

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // back row
            GestureDetector(
              onTap: widget.onBack,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        size: 13, color: _label),
                    SizedBox(width: 5),
                    Text(
                      'Back',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _label),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(l.createAccount, style: _headStyle(context)),
            const SizedBox(height: 6),
            Text(l.startManagingYourBusiness,
                style: const TextStyle(fontSize: 14, color: _muted)),
            const SizedBox(height: 36),

            _Lbl(l.businessName),
            const SizedBox(height: 7),
            TextFormField(
              key: const Key('signup_business_name'),
              controller: widget.bizCtl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              style: _inputStyle,
              decoration: _inputDec(
                  hint: l.businessNameHint, icon: Icons.storefront_outlined),
              validator: widget.vBiz,
            ),
            const SizedBox(height: 18),

            _Lbl(l.phone),
            const SizedBox(height: 7),
            TextFormField(
              key: const Key('signup_phone'),
              controller: widget.phoneCtl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: _inputStyle,
              decoration: _inputDec(
                  hint: '98XXXXXXXX', icon: Icons.phone_outlined),
              validator: widget.vPhone,
            ),
            const SizedBox(height: 18),

            _Lbl(l.password),
            const SizedBox(height: 7),
            TextFormField(
              key: const Key('signup_password'),
              controller: widget.passCtl,
              obscureText: _hide,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => widget.onSubmit(),
              style: _inputStyle,
              decoration: _inputDec(
                hint: l.passwordHint,
                icon: Icons.lock_outline_rounded,
                eye: _Eye(
                  hide: _hide,
                  onTap: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: widget.vPass,
            ),
            const SizedBox(height: 28),

            if (widget.auth.error != null) ...[
              _ErrBanner(widget.auth.error!),
              const SizedBox(height: 14),
            ],

            _Btn(
              label: l.createAccount,
              loading: widget.auth.loading,
              onPressed: widget.onSubmit,
            ),
            const SizedBox(height: 32),
            _Switch(
              question: l.haveAccount,
              action: l.login,
              onTap: widget.onSwitchLogin,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── shared micro-widgets ─────────────────────────────────────────────────────

TextStyle _headStyle(BuildContext ctx) =>
    Theme.of(ctx).textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.w700,
          color: _label,
          letterSpacing: -0.5,
          height: 1.1,
        );

const _inputStyle = TextStyle(fontSize: 15, color: _label);

InputDecoration _inputDec({
  required String hint,
  required IconData icon,
  Widget? eye,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BAB7), fontSize: 14),
      prefixIcon:
          Icon(icon, size: 19, color: _muted),
      suffixIcon: eye,
      filled: true,
      fillColor: _surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border:            _ob(_border),
      enabledBorder:     _ob(_border),
      focusedBorder:     _ob(_primary, w: 1.6),
      errorBorder:       _ob(_errText),
      focusedErrorBorder: _ob(_errText, w: 1.6),
      errorStyle: const TextStyle(fontSize: 12, height: 1.3),
    );

OutlineInputBorder _ob(Color c, {double w = 1.0}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

// brand
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext ctx) => Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
                Icons.store_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SME Digital',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Business Manager',
                style: TextStyle(
                    fontSize: 11, color: _muted, letterSpacing: 0.1),
              ),
            ],
          ),
        ],
      );
}

// field label
class _Lbl extends StatelessWidget {
  const _Lbl(this.text);
  final String text;

  @override
  Widget build(BuildContext _) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _label),
      );
}

// eye toggle
class _Eye extends StatelessWidget {
  const _Eye({required this.hide, required this.onTap});
  final bool hide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext _) => IconButton(
        icon: Icon(
          hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 19,
          color: _muted,
        ),
        onPressed: onTap,
        splashRadius: 20,
      );
}

// primary button
class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext _) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: _primary.withAlpha(180),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2),
                ),
        ),
      );
}

// error banner
class _ErrBanner extends StatelessWidget {
  const _ErrBanner(this.msg);
  final String msg;

  @override
  Widget build(BuildContext _) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _errBg,
          border: Border.all(color: _errBdr),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 16, color: _errText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontSize: 13, color: _errText)),
            ),
          ],
        ),
      );
}

// switch prompt ("Don't have an account? Sign up")
class _Switch extends StatelessWidget {
  const _Switch({
    required this.question,
    required this.action,
    required this.onTap,
  });
  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$question ',
              style: const TextStyle(fontSize: 14, color: _muted)),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 14,
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}
