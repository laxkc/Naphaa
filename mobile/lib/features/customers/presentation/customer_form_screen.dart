import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/customer.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customer});
  final Customer? customer;

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtl =
      TextEditingController(text: widget.customer?.name ?? '');
  late final _phoneCtl =
      TextEditingController(text: widget.customer?.phone ?? '');
  late final _addressCtl =
      TextEditingController(text: widget.customer?.address ?? '');
  late final _notesCtl =
      TextEditingController(text: widget.customer?.notes ?? '');
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.customer != null;

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Customer' : 'Add Customer'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneCtl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (optional)',
                  hintText: '98XXXXXXXX',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  hintText: 'Street, City',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesCtl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any additional notes',
                ),
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                InlineBanner(type: BannerType.error, message: _error!),
              ],
              const SizedBox(height: AppSpacing.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Save Changes' : 'Add Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(customersRepositoryProvider);
      if (_isEdit) {
        final updated = widget.customer!.copyWith(
          name: _nameCtl.text.trim(),
          phone: _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
          address: _addressCtl.text.trim().isEmpty
              ? null
              : _addressCtl.text.trim(),
          notes:
              _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
        );
        await repo.updateCustomer(updated);
        ref.invalidate(customerDetailProvider(widget.customer!.id));
      } else {
        await repo.addCustomer(
          name: _nameCtl.text.trim(),
          phone: _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
        );
      }
      ref.invalidate(customersListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save customer. Try again.';
      });
    }
  }
}
