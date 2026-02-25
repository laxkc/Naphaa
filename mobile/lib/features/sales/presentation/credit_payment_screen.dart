import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sme_digital/core/l10n/display_labels.dart';
import 'package:sme_digital/l10n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';

class CreditPaymentScreen extends ConsumerStatefulWidget {
  const CreditPaymentScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.outstandingBalance,
  });
  final String customerId;
  final String customerName;
  final double outstandingBalance;

  @override
  ConsumerState<CreditPaymentScreen> createState() =>
      _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends ConsumerState<CreditPaymentScreen> {
  final _amountController = TextEditingController();
  String _method = 'CASH';
  bool _loading = false;
  String? _error;
  final _currFmt = NumberFormat('#,##0.00');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.enterValidAmount);
      return;
    }
    if (amount > widget.outstandingBalance) {
      setState(() => _error = l10n.amountCannotExceedOutstandingBalance);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(customersRepositoryProvider);
      await repo.recordPayment(
        customerId: widget.customerId,
        amount: amount,
        method: _method,
      );
      ref.invalidate(customersListProvider);
      ref.invalidate(customerDetailProvider(widget.customerId));
      ref.invalidate(customerLedgerProvider(widget.customerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.paymentRecordedSuccessfully,
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = l10n.failedToRecordPaymentTryAgain;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.recordPaymentLabel),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.warningBg,
                        child: Text(
                          widget.customerName.isNotEmpty
                              ? widget.customerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.customerName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            Text(l10n.creditCustomerLabel,
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.h),
                  Text(l10n.outstandingBalanceLabel,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.nprLabel} ${_currFmt.format(widget.outstandingBalance)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: widget.outstandingBalance > 0
                              ? AppColors.warning
                              : AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.h),
            Text(l10n.paymentDetailsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.amountReceivedLabel,
                hintText: '0.00',
                prefixText: '${l10n.nprLabel} ',
                suffixIcon: TextButton(
                  onPressed: () => _amountController.text =
                      widget.outstandingBalance.toStringAsFixed(2),
                  child: Text(l10n.fullLabel),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.paymentMethodLabelTitle,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['CASH', 'QR', 'BANK'].map((m) {
                return ChoiceChip(
                  label: Text(paymentMethodLabel(context, m)),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                  showCheckmark: false,
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _method == m ? Colors.white : AppColors.label,
                    fontWeight: _method == m ? FontWeight.w700 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _method == m ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              InlineBanner(type: BannerType.error, message: _error!),
            ],
            const SizedBox(height: AppSpacing.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _recordPayment,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.recordPaymentLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
