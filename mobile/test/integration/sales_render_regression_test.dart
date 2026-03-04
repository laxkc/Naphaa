import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/core/date/business_clock.dart';
import 'package:sme_digital/core/date/calendar_adapter.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/features/sales/domain/sale.dart';
import 'package:sme_digital/features/sales/presentation/sale_detail_screen.dart';
import 'package:sme_digital/features/sales/presentation/sales_list_screen.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

class _EnglishLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

Widget _testShell(Widget child, {required List overrides}) {
  return ProviderScope(
    overrides: [
      localeControllerProvider.overrideWith(_EnglishLocaleController.new),
      businessClockProvider.overrideWith(
        (ref) async => BusinessClock.fallback(),
      ),
      calendarAdapterProvider.overrideWith(
        (ref) async => CalendarAdapter(calendarMode: 'BS', localeCode: 'en'),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Sale _sale({
  required String id,
  required SaleStatus status,
  required double totalAmount,
}) {
  return Sale(
    id: id,
    totalAmount: totalAmount,
    saleType: 'CASH',
    paymentMethod: 'CASH',
    createdAt: DateTime.utc(2026, 3, 4, 10, 30),
    saleDateAd: '2026-03-04',
    customerName: 'Customer $id',
    status: status,
    items: [
      SaleItem(
        id: 'item-1',
        productId: 'product-1',
        productName: 'Sugar',
        qty: 1,
        unitPrice: 100,
      ),
    ],
    payments: [SalePayment(id: 'pay-1', method: 'CASH', amount: 100)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('sales list renders corrected sale statuses without crash', (
    tester,
  ) async {
    final sales = [
      _sale(id: 's-void', status: SaleStatus.voided, totalAmount: 0),
      _sale(id: 's-partial', status: SaleStatus.partial, totalAmount: 50),
      _sale(id: 's-completed', status: SaleStatus.completed, totalAmount: 100),
    ];

    await tester.pumpWidget(
      _testShell(
        const SalesListScreen(standalone: true),
        overrides: [
          salesListProvider.overrideWith((ref, params) async => sales),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SalesListScreen), findsOneWidget);
    expect(find.text('VOIDED'), findsOneWidget);
    expect(find.text('PARTIAL'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sale detail renders correction actions and status without crash',
    (tester) async {
      final sale = _sale(
        id: 's-detail',
        status: SaleStatus.completed,
        totalAmount: 100,
      );
      await tester.pumpWidget(
        _testShell(
          const SaleDetailScreen(saleId: 's-detail'),
          overrides: [saleDetailProvider.overrideWith((ref, id) async => sale)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SaleDetailScreen), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Corrections'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
