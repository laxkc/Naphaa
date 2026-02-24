import 'package:flutter/material.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/landing_page.dart';
import 'shared/widgets/app_shell.dart';

class SmeDigitalApp extends ConsumerWidget {
  const SmeDigitalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final startup = ref.watch(appStartupProvider);
    ref.watch(syncCoordinatorProvider.notifier);

    return MaterialApp(
      title: 'SME Digital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ne')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home:
          auth.authenticated
              ? startup.when(
                data: (_) => const AppShell(),
                loading:
                    () => const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                error: (_, __) => const AppShell(),
              )
              : const LandingPage(),
    );
  }
}
