import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/app.dart';
import 'package:sme_digital/core/config/environment_config.dart';
import 'package:sme_digital/core/date/business_clock.dart';
import 'package:sme_digital/core/date/calendar_adapter.dart';
import 'package:sme_digital/core/network/session_service.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/features/auth/domain/auth_state.dart';
import 'package:sme_digital/features/auth/presentation/auth_screen.dart';
import 'package:sme_digital/features/auth/presentation/language_selection_screen.dart';
import 'package:sme_digital/features/products/domain/product.dart';
import 'package:sme_digital/features/profile/presentation/profile_screen.dart';
import 'package:sme_digital/features/reports/domain/alert_item.dart';
import 'package:sme_digital/features/dashboard/presentation/dashboard_screen.dart';

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() =>
      AuthState(authenticated: true, phone: '9800000001', role: 'owner');
}

class _UnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() => AuthState(authenticated: false);
}

class _EnglishLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

class _IdleSyncCoordinatorController extends SyncCoordinatorController {
  @override
  SyncStatusState build() => const SyncStatusState();
}

const _testEnvironment = EnvironmentConfig(
  env: 'test',
  baseUrl: 'http://127.0.0.1:8000/api/v1',
  connectTimeoutSeconds: 5,
  receiveTimeoutSeconds: 5,
  sourceAssetPath: 'test',
);

Future<void> _pumpApp(
  WidgetTester tester, {
  required List overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(_testEnvironment),
        localeControllerProvider.overrideWith(_EnglishLocaleController.new),
        syncCoordinatorProvider.overrideWith(_IdleSyncCoordinatorController.new),
        ...overrides,
      ],
      child: const SmeDigitalApp(),
    ),
  );
  await tester.pumpAndSettle();
}

List _dashboardShellOverrides() {
  return [
    profileProvider.overrideWith(
      (ref) async => const ProfileData(
        phone: '9800000001',
        storeName: 'My Shop',
        localeDefault: 'en',
        currency: 'NPR',
        calendarMode: 'BS',
        businessTimezone: 'Asia/Kathmandu',
        role: 'owner',
      ),
    ),
    dashboardSummaryProvider.overrideWith(
      (ref) async => DashboardSummary(
        todaySales: 0,
        todayExpenses: 0,
        creditOutstanding: 0,
      ),
    ),
    lowStockProductsProvider.overrideWith((ref) async => const <Product>[]),
    productsListProvider.overrideWith((ref) async => const <Product>[]),
    alertsUnreadFeedProvider.overrideWith((ref) async => const <AlertItem>[]),
    setupPromptsProvider.overrideWith((ref) async => const <SetupPrompt>[]),
    firstRunSnapshotProvider.overrideWith(
      (ref) async => const FirstRunSnapshot(
        productCount: 0,
        customerCount: 0,
        saleCount: 0,
      ),
    ),
    businessClockProvider.overrideWith((ref) async => BusinessClock.fallback()),
    calendarAdapterProvider.overrideWith(
      (ref) async => CalendarAdapter(calendarMode: 'BS', localeCode: 'en'),
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('progressive onboarding startup flow', () {
    testWidgets('first install shows language selection first', (tester) async {
      await _pumpApp(
        tester,
        overrides: [
          hasLanguageSelectionProvider.overrideWith((ref) async => false),
          authControllerProvider.overrideWith(_UnauthenticatedAuthController.new),
        ],
      );

      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      expect(find.text('Choose your language'), findsOneWidget);
    });

    testWidgets('selected language and no session shows OTP auth', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        overrides: [
          hasLanguageSelectionProvider.overrideWith((ref) async => true),
          authControllerProvider.overrideWith(_UnauthenticatedAuthController.new),
        ],
      );

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Continue with your phone number'), findsOneWidget);
    });

    testWidgets('authenticated returning user lands on dashboard directly', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        overrides: [
          hasLanguageSelectionProvider.overrideWith((ref) async => true),
          authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
          appStartupProvider.overrideWith((ref) async {}),
          ..._dashboardShellOverrides(),
        ],
      );

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Welcome to Naphaa'), findsOneWidget);
      expect(find.text('Setup Business'), findsAtLeastNWidgets(1));
    });

    testWidgets('expired authenticated startup returns user to auth flow', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        overrides: [
          hasLanguageSelectionProvider.overrideWith((ref) async => true),
          authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
          appStartupProvider.overrideWith(
            (ref) async => throw const SessionAuthException(
              code: 'UNAUTHENTICATED',
              message: 'Session expired. Please sign in again.',
            ),
          ),
        ],
      );

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });
  });
}
