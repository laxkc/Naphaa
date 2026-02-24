import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/context_i18n.dart';
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
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = context.tr('Enter a valid amount', 'मान्य रकम लेख्नुहोस्'));
      return;
    }
    if (amount > widget.outstandingBalance) {
      setState(() => _error = context.tr(
            'Amount cannot exceed outstanding balance',
            'रकम बाँकी उधारो भन्दा बढी हुन सक्दैन',
          ));
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
              context.tr('Payment recorded successfully', 'भुक्तानी सफलतापूर्वक रेकर्ड भयो'),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = context.tr(
          'Failed to record payment. Try again.',
          'भुक्तानी रेकर्ड गर्न सकेन। फेरि प्रयास गर्नुहोस्।',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('Record Payment', 'भुक्तानी रेकर्ड गर्नुहोस्')),
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
                            Text(context.tr('Credit Customer', 'उधारो ग्राहक'),
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.h),
                  Text(context.tr('Outstanding Balance', 'बाँकी उधारो'),
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    'NPR ${_currFmt.format(widget.outstandingBalance)}',
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
            Text(context.tr('Payment Details', 'भुक्तानी विवरण'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.tr('Amount Received', 'प्राप्त रकम'),
                hintText: '0.00',
                prefixText: 'NPR ',
                suffixIcon: TextButton(
                  onPressed: () => _amountController.text =
                      widget.outstandingBalance.toStringAsFixed(2),
                  child: Text(context.tr('Full', 'पूरै')),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.tr('Payment Method', 'भुक्तानी विधि'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['CASH', 'QR', 'BANK'].map((m) {
                return ChoiceChip(
                  label: Text(m),
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
                    : Text(context.tr('Record Payment', 'भुक्तानी रेकर्ड गर्नुहोस्')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
