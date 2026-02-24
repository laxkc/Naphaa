import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/features/products/domain/product.dart';
import 'package:sme_digital/features/reports/domain/alert_item.dart';
import 'package:sme_digital/features/reports/domain/product_metric_item.dart';
import 'package:sme_digital/features/reports/presentation/business_health_screen.dart';
import 'package:sme_digital/features/reports/presentation/credit_aging_report_screen.dart';
import 'package:sme_digital/features/reports/presentation/product_insights_report_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Intelligence/Risk UI', () {
    testWidgets(
      'BusinessHealthScreen renders canonical business metrics and previews',
      (tester) async {
        final riskParams = const CustomerMetricsQueryParams(limit: 500);
        final productParams = const ProductMetricsQueryParams(
          limit: 200,
          windowDays: 30,
          deadStockDays: 30,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              businessMetricsProvider.overrideWith((ref) async {
                return {
                  'sales_total': 1200,
                  'expenses_total': 450,
                  'profit_est': 750,
                  'profit_margin': 62.5,
                  'outstanding_total': 800,
                  'cash_risk_level': 'high',
                  'reasons': [
                    'Overdue credit NPR 500.00',
                    '2 high-risk customer(s)',
                  ],
                  'source': 'local_cache',
                };
              }),
              customerMetricsReportProvider(riskParams).overrideWith((
                ref,
              ) async {
                return {
                  'items': [
                    {
                      'customer_id': 'c1',
                      'customer_name': 'Ram',
                      'outstanding_amount': 500,
                      'oldest_due_days': 22,
                      'risk_level': 'red',
                    },
                  ],
                  'total_outstanding': 800,
                  'total_overdue': 500,
                  'high_risk_count': 2,
                  'source': 'local_cache',
                };
              }),
              alertsFeedProvider.overrideWith((ref) async {
                return [
                  AlertItem(
                    id: 'a1',
                    type: 'credit_overdue',
                    severity: 'critical',
                    title: 'Ram credit overdue (22d)',
                    body: 'Ram owes NPR 500.00',
                    entityType: 'customer',
                    entityId: 'c1',
                  ),
                ];
              }),
              lowStockProductsProvider.overrideWith((ref) async {
                return [
                  Product(
                    id: 'p1',
                    name: 'WaiWai',
                    sellPrice: 20,
                    stockQty: 2,
                    lowStockThreshold: 5,
                    unit: 'pcs',
                  ),
                ];
              }),
              productMetricsReportProvider(productParams).overrideWith((
                ref,
              ) async {
                return {
                  'items': [
                    ProductMetricItem(
                      productId: 'p1',
                      productName: 'WaiWai',
                      stockQty: 2,
                      qtySold7d: 18,
                      qtySold30d: 42,
                      revenue30d: 840,
                      deadStock: false,
                      profit30d: 210,
                    ),
                  ],
                  'dead_stock_count': 0,
                  'dead_stock_value_total': 0,
                  'source': 'local_cache',
                };
              }),
            ],
            child: const MaterialApp(home: BusinessHealthScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Business Health'), findsOneWidget);
        expect(find.text('HIGH'), findsOneWidget);
        expect(
          find.textContaining('Overdue credit NPR 500.00'),
          findsOneWidget,
        );
        expect(find.textContaining('cached intelligence data'), findsOneWidget);
      },
    );

    testWidgets(
      'ProductInsightsReportScreen renders fast movers and top profit sections',
      (tester) async {
        final params = const ProductMetricsQueryParams(
          deadStockOnly: false,
          limit: 500,
          windowDays: 30,
          deadStockDays: 30,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productMetricsReportProvider(params).overrideWith((ref) async {
                return {
                  'items': [
                    ProductMetricItem(
                      productId: 'p-fast',
                      productName: 'Noodles',
                      stockQty: 10,
                      qtySold7d: 12,
                      qtySold30d: 30,
                      revenue30d: 1200,
                      profit30d: 450,
                      deadStock: false,
                    ),
                    ProductMetricItem(
                      productId: 'p-dead',
                      productName: 'Old Biscuit',
                      stockQty: 8,
                      qtySold7d: 0,
                      qtySold30d: 0,
                      revenue30d: 0,
                      deadStock: true,
                      deadStockValue: 144,
                    ),
                  ],
                  'dead_stock_count': 1,
                  'dead_stock_value_total': 144,
                  'source': 'local_cache',
                };
              }),
            ],
            child: const MaterialApp(home: ProductInsightsReportScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Product Insights'), findsOneWidget);
        expect(find.textContaining('Top Profit Products'), findsOneWidget);
        expect(find.textContaining('Fast Movers'), findsOneWidget);
        expect(find.textContaining('Noodles'), findsWidgets);
        // Dead stock list can be below the fold in this screen; summary proves it rendered.
        expect(find.textContaining('Dead Stock Items'), findsOneWidget);
        expect(find.textContaining('1'), findsWidgets);
        expect(find.textContaining('cached product insights'), findsOneWidget);
      },
    );

    testWidgets(
      'CreditAgingReportScreen shows cached-data hint for local cache source',
      (tester) async {
        const params = CustomerMetricsQueryParams(limit: 500);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerMetricsReportProvider(params).overrideWith((ref) async {
                return {
                  'items': [
                    {
                      'customer_id': 'c1',
                      'customer_name': 'Ram',
                      'phone': '9800000001',
                      'risk_level': 'red',
                      'risk_score': 74,
                      'oldest_due_days': 22,
                      'outstanding_amount': 500,
                      'aging': {
                        'd0_7': 0,
                        'd8_30': 500,
                        'd31_60': 0,
                        'd60_plus': 0,
                      },
                    },
                  ],
                  'totals': {
                    'd0_7': 0,
                    'd8_30': 500,
                    'd31_60': 0,
                    'd60_plus': 0,
                  },
                  'total_outstanding': 500,
                  'total_overdue': 500,
                  'high_risk_count': 1,
                  'source': 'local_cache',
                };
              }),
            ],
            child: const MaterialApp(home: CreditAgingReportScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Credit Aging'), findsOneWidget);
        expect(find.textContaining('cached credit aging data'), findsOneWidget);
        expect(find.textContaining('Credit Aging Summary'), findsOneWidget);
      },
    );
  });
}
