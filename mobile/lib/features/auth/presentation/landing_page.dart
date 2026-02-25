import 'package:flutter/material.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Brand icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'SME Digital',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.authLandingSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.h),
              _FeatureBullet(
                icon: Icons.bolt_rounded,
                label: l10n.authLandingFeatureFastSales,
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureBullet(
                icon: Icons.wifi_off_rounded,
                label: l10n.authLandingFeatureOfflineSync,
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureBullet(
                icon: Icons.people_rounded,
                label: l10n.authLandingFeatureCreditTracking,
              ),
              const Spacer(),
              // CTA buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () => _goToAuth(context, showRegister: true),
                  child: Text(
                    l10n.authLandingStartFree,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    side: const BorderSide(color: Colors.white54),
                  ),
                  onPressed: () => _goToAuth(context, showRegister: false),
                  child: Text(
                    l10n.login,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _goToAuth(BuildContext context, {required bool showRegister}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(initialShowRegister: showRegister),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
