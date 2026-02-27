import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/features/billing/domain/invoice_models.dart';
import 'package:sme_digital/features/billing/presentation/invoice_list_screen.dart';
import 'package:sme_digital/features/dashboard/presentation/dashboard_screen.dart';
import 'package:sme_digital/features/products/domain/product.dart';
import 'package:sme_digital/features/reports/domain/alert_item.dart';
import 'package:sme_digital/features/reports/presentation/credit_report_screen.dart';
import 'package:sme_digital/features/customers/domain/customer.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('High-risk UI regression', () {
    testWidgets('Dashboard survives small viewport without overflow', (
      tester,
    ) async {
      final view = tester.view;
      view.devicePixelRatio = 1.0;
      view.physicalSize = const Size(320, 640);
      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) async {
              return DashboardSummary(
                todaySales: 52340.0,
                todayExpenses: 21450.0,
                creditOutstanding: 9800.0,
              );
            }),
            lowStockProductsProvider.overrideWith((ref) async {
              return [
                Product(
                  id: 'p1',
                  name: 'Very Long Product Name For Overflow Verification',
                  sellPrice: 120,
                  stockQty: 2,
                  lowStockThreshold: 5,
                  unit: 'pcs',
                ),
              ];
            }),
            alertsUnreadFeedProvider.overrideWith((ref) async {
              return const [
                AlertItem(
                  id: 'a1',
                  type: 'credit_overdue',
                  severity: 'critical',
                  title: 'Critical credit overdue',
                  body: 'Customer overdue by 45 days',
                  entityType: 'customer',
                ),
              ];
            }),
          ],
          child: _testApp(const DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_outlined), findsWidgets);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Invoice list renders compact summary on small viewport', (
      tester,
    ) async {
      final view = tester.view;
      view.devicePixelRatio = 1.0;
      view.physicalSize = const Size(320, 640);
      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoicesListProvider.overrideWith((ref) async {
              return [
                InvoiceRecord(
                  id: 'i1',
                  businessId: 'b1',
                  status: InvoiceStatus.overdue,
                  invoiceNumber: 'INV-2026-00001-VERY-LONG',
                  currencyCode: 'NPR',
                  languageSnapshot: 'en',
                  subtotal: 1200,
                  discountAmount: 0,
                  taxAmount: 156,
                  total: 1356,
                  paidAmount: 200,
                  balanceDue: 1156,
                  issueDate: DateTime(2026, 2, 20, 12, 0),
                ),
              ];
            }),
          ],
          child: _testApp(const InvoiceListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invoices'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Balance'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Credit report header remains stable for long values', (
      tester,
    ) async {
      final view = tester.view;
      view.devicePixelRatio = 1.0;
      view.physicalSize = const Size(320, 640);
      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            creditReportProvider.overrideWith((ref) async {
              return [
                Customer(
                  id: 'c1',
                  name:
                      'Customer With An Exceptionally Long Name For Regression Checks',
                  phone: '9800000001',
                  balance: 987654.32,
                ),
              ];
            }),
            customerRiskMetricsProvider.overrideWith((ref) async => const {}),
          ],
          child: _testApp(const CreditReportScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Credit Report'), findsOneWidget);
      expect(find.textContaining('Total Outstanding'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _testApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
