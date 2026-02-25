import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../customers/presentation/customer_detail_screen.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../domain/alert_item.dart';
import 'alerts_feed_screen.dart';
import 'business_health_screen.dart';
import 'credit_aging_report_screen.dart';
import 'credit_report_screen.dart';
import 'ledger_report_screen.dart';
import 'product_insights_report_screen.dart';
import 'profit_report_screen.dart';
import 'sales_report_screen.dart';

class AlertActionRouter {
  static bool canHandle(AlertItem alert) {
    final action = (alert.actionType ?? '').trim().toLowerCase();
    if (action.isEmpty) return false;
    return switch (action) {
      'open_customer' => _customerId(alert) != null,
      'open_product' => _productId(alert) != null,
      'view_report' => true,
      _ => false,
    };
  }

  static Future<void> open(BuildContext context, AlertItem alert) async {
    final action = (alert.actionType ?? '').trim().toLowerCase();
    switch (action) {
      case 'open_customer':
        final customerId = _customerId(alert);
        if (customerId == null) return _showUnavailable(context);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(customerId: customerId),
          ),
        );
        return;
      case 'open_product':
        final productId = _productId(alert);
        if (productId == null) return _showUnavailable(context);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: productId),
          ),
        );
        return;
      case 'view_report':
        final route = _reportRoute(alert);
        if (route == null) return _showUnavailable(context);
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => route));
        return;
      default:
        _showUnavailable(context);
    }
  }

  static String? _customerId(AlertItem alert) {
    final fromPayload = alert.actionPayload?['customer_id']?.toString();
    if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;
    if ((alert.entityType).toLowerCase() == 'customer') {
      final id = alert.entityId?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  static String? _productId(AlertItem alert) {
    final fromPayload = alert.actionPayload?['product_id']?.toString();
    if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;
    if ((alert.entityType).toLowerCase() == 'product') {
      final id = alert.entityId?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  static Widget? _reportRoute(AlertItem alert) {
    final raw =
        alert.actionPayload?['report']?.toString() ??
        alert.actionPayload?['report_key']?.toString() ??
        alert.type;
    final key = raw.trim().toLowerCase();
    return switch (key) {
      'credit_aging' || 'credit-aging' => const CreditAgingReportScreen(),
      'credit_report' || 'credit' => const CreditReportScreen(),
      'sales_report' || 'sales' => const SalesReportScreen(),
      'profit_report' || 'profit' => const ProfitReportScreen(),
      'product_insights' || 'products' => const ProductInsightsReportScreen(),
      'ledger' || 'ledger_report' => const LedgerReportScreen(),
      'business_health' || 'health' => const BusinessHealthScreen(),
      'alerts' || 'alerts_feed' => const AlertsFeedScreen(),
      _ => null,
    };
  }

  static void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.alertsActionUnavailable,
        ),
      ),
    );
  }
}
