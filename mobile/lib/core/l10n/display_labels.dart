import 'package:flutter/widgets.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import 'package:sme_digital/features/billing/domain/invoice_models.dart';

String riskLevelLabel(
  BuildContext context,
  String level, {
  bool short = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  return switch (level.trim().toLowerCase()) {
    'red' =>
      short
          ? l10n.highLabel
          : l10n.highRiskLabel,
    'yellow' =>
      short
          ? l10n.mediumLabel
          : l10n.mediumRiskLabel,
    _ => short ? l10n.lowLabel : l10n.lowRiskLabel,
  };
}

String alertSeverityLabel(BuildContext context, String severity) {
  final l10n = AppLocalizations.of(context)!;
  return switch (severity.trim().toLowerCase()) {
    'critical' => l10n.criticalLabel,
    'warn' => l10n.warningLabel,
    _ => l10n.infoLabel,
  };
}

String paymentMethodLabel(BuildContext context, String method) {
  final l10n = AppLocalizations.of(context)!;
  return switch (method.trim().toUpperCase()) {
    'CASH' => l10n.paymentMethodCashLabel,
    'BANK' => l10n.paymentMethodBankLabel,
    'QR' => l10n.paymentMethodQrLabel,
    'CREDIT' => l10n.paymentMethodCreditLabel,
    _ => method.toUpperCase(),
  };
}

String invoiceStatusLabel(BuildContext context, InvoiceStatus status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    InvoiceStatus.draft => l10n.invoiceStatusDraftLabel,
    InvoiceStatus.issued => l10n.invoiceStatusIssuedLabel,
    InvoiceStatus.paid => l10n.invoiceStatusPaidLabel,
    InvoiceStatus.overdue => l10n.invoiceStatusOverdueLabel,
    InvoiceStatus.cancelled => l10n.invoiceStatusCancelledLabel,
  };
}
