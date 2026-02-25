import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/core/network/backend_gateway.dart';
import 'package:sme_digital/core/network/session_service.dart';
import 'package:sme_digital/core/storage/secure_storage.dart';
import 'package:sme_digital/features/reports/domain/alert_item.dart';
import 'package:sme_digital/features/reports/domain/product_metric_item.dart';

import '../helpers/test_db.dart';

class _TestLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

class _FailingSessionService extends SessionService {
  _FailingSessionService()
    : super(
        BackendGateway(Dio()),
        SecureTokenStorage(const FlutterSecureStorage()),
        Dio(),
      );

  @override
  Future<void> ensureReady({required String localeCode}) async {
    throw const SessionAuthException(
      code: 'UNAUTHENTICATED',
      message: 'offline for test',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Intelligence metrics/alerts providers', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'business/alerts/product metrics providers recompute after invalidation',
      () async {
        final counts = <String, int>{};
        const productParams = ProductMetricsQueryParams(
          deadStockOnly: false,
          limit: 200,
          windowDays: 30,
          deadStockDays: 30,
        );

        final container = ProviderContainer(
          overrides: [
            localeControllerProvider.overrideWith(_TestLocaleController.new),
            businessMetricsProvider.overrideWith((ref) async {
              counts['business'] = (counts['business'] ?? 0) + 1;
              return {
                'sales_total': 100.0,
                'expenses_total': 40.0,
                'profit_est': 60.0,
                'profit_margin': 60.0,
                'outstanding_total': 20.0,
                'cash_risk_level': 'low',
                'reasons': const <String>[],
              };
            }),
            alertsFeedProvider.overrideWith((ref) async {
              counts['alerts'] = (counts['alerts'] ?? 0) + 1;
              return const [
                AlertItem(
                  id: 'a1',
                  type: 'credit_overdue',
                  severity: 'warn',
                  title: 'Overdue',
                  body: 'Test alert',
                  entityType: 'customer',
                ),
              ];
            }),
            productMetricsReportProvider(productParams).overrideWith((
              ref,
            ) async {
              counts['products'] = (counts['products'] ?? 0) + 1;
              return {
                'items': const [
                  ProductMetricItem(
                    productId: 'p1',
                    productName: 'WaiWai',
                    stockQty: 2,
                    qtySold7d: 5,
                    qtySold30d: 12,
                    revenue30d: 240,
                    deadStock: false,
                    profit30d: 60,
                  ),
                ],
                'dead_stock_count': 0,
                'dead_stock_value_total': 0.0,
              };
            }),
          ],
        );
        addTearDown(container.dispose);

        await container.read(businessMetricsProvider.future);
        await container.read(alertsFeedProvider.future);
        await container.read(
          productMetricsReportProvider(productParams).future,
        );

        expect(counts['business'], 1);
        expect(counts['alerts'], 1);
        expect(counts['products'], 1);

        container.invalidate(businessMetricsProvider);
        container.invalidate(alertsFeedProvider);
        container.invalidate(productMetricsReportProvider(productParams));

        await container.read(businessMetricsProvider.future);
        await container.read(alertsFeedProvider.future);
        await container.read(
          productMetricsReportProvider(productParams).future,
        );

        expect(counts['business'], greaterThanOrEqualTo(2));
        expect(counts['alerts'], greaterThanOrEqualTo(2));
        expect(counts['products'], greaterThanOrEqualTo(2));
      },
    );

    test(
      'alerts provider override delivers typed alert items to consumers',
      () async {
        final container = ProviderContainer(
          overrides: [
            localeControllerProvider.overrideWith(_TestLocaleController.new),
            alertsFeedProvider.overrideWith((ref) async {
              return [
                AlertItem(
                  id: 'old',
                  type: 'credit_overdue',
                  severity: 'warn',
                  title: 'Old',
                  body: 'Old',
                  entityType: 'customer',
                  createdAt: DateTime.parse('2026-02-24T10:00:00Z'),
                ),
                AlertItem(
                  id: 'new',
                  type: 'expense_spike',
                  severity: 'critical',
                  title: 'New',
                  body: 'New',
                  entityType: 'business',
                  createdAt: DateTime.parse('2026-02-24T12:00:00Z'),
                ),
              ];
            }),
          ],
        );
        addTearDown(container.dispose);

        final items = await container.read(alertsFeedProvider.future);
        expect(items, hasLength(2));
        expect(items.map((e) => e.id), containsAll(['old', 'new']));
      },
    );

    test(
      'customer metrics and alerts fall back to local cache when backend is unavailable',
      () async {
        final localDb = await createTestDb('intelligence_provider_local_cache');
        final db = await localDb.database;
        addTearDown(localDb.reset);

        await db.insert('customers', {
          'id': 'c1',
          'name': 'Ram',
          'phone': '9800000001',
          'address': null,
          'notes': null,
          'balance': 500.0,
          'created_at': '2026-02-24T10:00:00Z',
          'is_deleted': 0,
          'updated_at': '2026-02-24T10:00:00Z',
        });
        await db.insert('customer_metrics', {
          'customer_id': 'c1',
          'outstanding_amount': 500.0,
          'oldest_due_days': 22,
          'avg_days_to_pay': 14.0,
          'on_time_rate': 0.3,
          'payment_frequency_30d': 2.0,
          'risk_score': 74,
          'risk_level': 'red',
          'explanation_json':
              '{"oldest_due_factor":0.5,"avg_days_to_pay_factor":0.4,"late_behavior_factor":0.7,"outstanding_spike_factor":0.3}',
          'version': 1,
          'computed_at': '2026-02-24T12:00:00Z',
        });
        await db.insert('alerts', {
          'id': 'a1',
          'type': 'credit_overdue',
          'entity_type': 'customer',
          'entity_id': 'c1',
          'severity': 'critical',
          'title': 'Ram overdue',
          'body': 'Ram owes NPR 500',
          'action_type': 'open_customer',
          'action_payload_json': '{"customer_id":"c1"}',
          'created_at': '2026-02-24T12:05:00Z',
          'resolved_at': null,
        });
        await db.insert('product_metrics', {
          'product_id': 'p1',
          'product_name': 'WaiWai',
          'stock_qty': 2.0,
          'cost_price': 12.0,
          'qty_sold_7d': 18.0,
          'qty_sold_30d': 42.0,
          'revenue_30d': 840.0,
          'profit_30d': 210.0,
          'last_sale_at': '2026-02-24T11:00:00Z',
          'dead_stock': 0,
          'dead_stock_value': 0.0,
          'computed_at': '2026-02-24T12:00:00Z',
        });
        await db.insert('business_metrics_cache', {
          'cache_key': 'default',
          'from_date': null,
          'to_date': null,
          'payload_json':
              '{"sales_total":1200,"expenses_total":450,"profit_est":750,"profit_margin":62.5,"outstanding_total":800,"cash_risk_level":"high","reasons":["Overdue credit NPR 500.00"]}',
          'computed_at': '2026-02-24T12:00:00Z',
        });

        final container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWithValue(localDb),
            localeControllerProvider.overrideWith(_TestLocaleController.new),
            sessionServiceProvider.overrideWith(
              (ref) => _FailingSessionService(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final riskMap = await container.read(
          customerRiskMetricsProvider.future,
        );
        expect(riskMap['c1'], isNotNull);
        expect(riskMap['c1']!.riskLevel, 'red');
        expect(riskMap['c1']!.riskScore, 74);

        final report = await container.read(
          customerMetricsReportProvider(
            const CustomerMetricsQueryParams(limit: 50),
          ).future,
        );
        expect(report['source'], 'local_cache');
        expect(report['high_risk_count'], 1);
        expect((report['items'] as List).length, 1);
        expect(
          ((report['items'] as List).first as Map)['customer_name'],
          'Ram',
        );

        final alerts = await container.read(alertsFeedProvider.future);
        expect(alerts, hasLength(1));
        expect(alerts.first.id, 'a1');
        expect(alerts.first.title, 'Ram overdue');

        final productReport = await container.read(
          productMetricsReportProvider(
            const ProductMetricsQueryParams(limit: 50),
          ).future,
        );
        expect(productReport['source'], 'local_cache');
        expect((productReport['items'] as List), hasLength(1));
        final product =
            (productReport['items'] as List).first as ProductMetricItem;
        expect(product.productId, 'p1');
        expect(product.qtySold7d, 18);

        final business = await container.read(businessMetricsProvider.future);
        expect(business['source'], 'local_cache');
        expect(business['cash_risk_level'], 'high');
        expect(business['sales_total'], 1200);
      },
    );
  });
}
