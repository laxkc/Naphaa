import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../customers/domain/customer.dart';
import '../products/data/products_repository.dart';
import '../products/domain/product.dart';
import '../customers/data/customers_repository.dart';
import 'data/sales_repository.dart';
import 'domain/sale_models.dart';
import 'sales_state.dart';

class SalesController extends Notifier<SalesState> {
  late final SalesRepository _salesRepository;
  late final ProductsRepository _productsRepository;
  late final CustomersRepository _customersRepository;

  @override
  SalesState build() {
    _salesRepository = ref.watch(salesRepositoryProvider);
    _productsRepository = ref.watch(productsRepositoryProvider);
    _customersRepository = ref.watch(customersRepositoryProvider);
    Future.microtask(() async {
      if (!ref.mounted) return;
      try {
        await search('');
      } catch (e) {
        if (!ref.mounted) return;
        state = state.copyWith(
          loading: false,
          message: 'Failed to load products: $e',
        );
      }
    });
    return SalesState();
  }

  Future<void> search(String query, {bool clearMessage = true}) async {
    try {
      state = state.copyWith(
        loading: true,
        search: query,
        message: clearMessage ? null : state.message,
      );
      final products = await _productsRepository.searchProducts(query);
      final recentProducts = await _productsRepository.recentProducts();
      state = state.copyWith(
        loading: false,
        products: products,
        recentProducts: recentProducts,
        message: clearMessage ? null : state.message,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        message: 'Failed to search products: $e',
      );
    }
  }

  void increment(String productId) {
    final selected = Map<String, int>.from(state.selected);
    selected[productId] = (selected[productId] ?? 0) + 1;
    state = state.copyWith(selected: selected, message: null);
  }

  void decrement(String productId) {
    final selected = Map<String, int>.from(state.selected);
    final current = selected[productId] ?? 0;
    if (current <= 1) {
      selected.remove(productId);
    } else {
      selected[productId] = current - 1;
    }
    state = state.copyWith(selected: selected, message: null);
  }

  Future<bool> saveCashSale() async {
    return _saveSale(saleType: 'CASH', paymentMethod: PaymentMethod.cash);
  }

  Future<bool> saveCreditSale() async {
    return _saveSale(saleType: 'CREDIT', paymentMethod: PaymentMethod.credit);
  }

  Future<bool> saveCreditSaleWithCustomer({
    required String customerName,
    String? phone,
  }) async {
    final name = customerName.trim();
    final cleanPhone = phone?.trim() ?? '';
    if (name.isEmpty) {
      state = state.copyWith(
        message: 'Customer name is required for credit sale.',
      );
      return false;
    }
    if (cleanPhone.isEmpty) {
      state = state.copyWith(
        message:
            'Phone number is required for credit sale. Choose existing customer if phone is unavailable.',
      );
      return false;
    }
    late final String customerId;
    try {
      customerId = await _resolveOrCreateCustomerId(
        customerName: name,
        phone: cleanPhone,
      );
    } catch (e) {
      final descriptor = _describeSaveError(e);
      state = state.copyWith(message: descriptor.message);
      return false;
    }
    return _saveSale(
      saleType: 'CREDIT',
      paymentMethod: PaymentMethod.credit,
      customerId: customerId,
    );
  }

  Future<bool> saveCreditSaleForCustomerId(String customerId) async {
    final clean = customerId.trim();
    if (clean.isEmpty) {
      state = state.copyWith(message: 'Select a customer for credit sale.');
      return false;
    }
    return _saveSale(
      saleType: 'CREDIT',
      paymentMethod: PaymentMethod.credit,
      customerId: clean,
    );
  }

  Future<bool> saveSaleWithPayments({
    required List<SalePaymentInput> payments,
    String? customerName,
    String? customerPhone,
  }) async {
    if (payments.isEmpty) {
      state = state.copyWith(message: 'Select at least one payment method.');
      return false;
    }
    final hasCredit = payments.any((p) => p.method == PaymentMethod.credit);
    String? customerId;
    if (hasCredit) {
      final name = customerName?.trim() ?? '';
      final phone = customerPhone?.trim() ?? '';
      if (name.isEmpty) {
        state = state.copyWith(
          message: 'Customer name is required when credit is included.',
        );
        return false;
      }
      if (phone.isEmpty) {
        state = state.copyWith(
          message:
              'Phone number is required when credit is included. Choose existing customer if phone is unavailable.',
        );
        return false;
      }
      try {
        customerId = await _resolveOrCreateCustomerId(
          customerName: name,
          phone: phone,
        );
      } catch (e) {
        final descriptor = _describeSaveError(e);
        state = state.copyWith(message: descriptor.message);
        return false;
      }
    }

    final saleType =
        hasCredit ? 'CREDIT' : (payments.length > 1 ? 'MIXED' : 'CASH');
    final paymentMethod =
        payments.length > 1 ? PaymentMethod.mixed : payments.first.method;
    return _saveSale(
      saleType: saleType,
      paymentMethod: paymentMethod,
      customerId: customerId,
      payments: payments,
    );
  }

  Future<void> quickAddProduct({
    required String name,
    required double sellPrice,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      state = state.copyWith(message: 'Product name is required.');
      return;
    }
    if (sellPrice <= 0) {
      state = state.copyWith(message: 'Price must be greater than zero.');
      return;
    }
    await _productsRepository.addProduct(
      name: cleanName,
      sellPrice: sellPrice,
      stockQty: 0,
    );
    await search(cleanName);
    final created =
        state.products
            .where((p) => p.name.toLowerCase() == cleanName.toLowerCase())
            .firstOrNull;
    if (created != null) {
      increment(created.id);
    }
    state = state.copyWith(message: 'Product created and added to cart.');
  }

  Future<bool> _saveSale({
    required String saleType,
    required PaymentMethod paymentMethod,
    String? customerId,
    List<SalePaymentInput> payments = const [],
  }) async {
    if (!state.canSave) {
      state = state.copyWith(message: 'Please add at least one product.');
      return false;
    }

    final checkoutStart = DateTime.now();
    try {
      state = state.copyWith(loading: true, message: null);
      final items = <SaleItemInput>[];
      var cartItemCount = 0;
      for (final entry in state.selected.entries) {
        final product = _findProduct(entry.key);
        cartItemCount += entry.value;
        items.add(
          SaleItemInput(
            productId: product.id,
            qty: entry.value.toDouble(),
            unitPrice: product.sellPrice,
          ),
        );
      }

      await _salesRepository.createSale(
        SaleInput(
          saleType: saleType,
          paymentMethod: paymentMethod,
          customerId: customerId,
          items: items,
          payments: payments,
        ),
      );
      var syncRetryNotice = false;
      final localeCode = ref.read(localeControllerProvider).languageCode;
      try {
        await ref
            .read(syncManagerProvider)
            .processPendingSync(localeCode: localeCode);
      } catch (_) {
        // Local save already succeeded; keep checkout successful and retry sync later.
        syncRetryNotice = true;
      }
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(customersListProvider);
      ref.invalidate(expensesListProvider);

      final successMessage =
          saleType == 'CREDIT'
              ? 'Credit sale saved successfully.'
              : saleType == 'MIXED'
              ? 'Sale saved successfully.'
              : 'Cash sale saved successfully.';
      final message =
          syncRetryNotice
              ? '$successMessage Sync failed. Will retry automatically.'
              : successMessage;
      await search(state.search, clearMessage: false);
      final durationMs =
          DateTime.now().difference(checkoutStart).inMilliseconds;
      await _recordCheckoutDiagnostic(
        flow: _checkoutFlow(
          saleType: saleType,
          paymentMethod: paymentMethod,
          payments: payments,
        ),
        saleType: saleType,
        paymentMethod: paymentMethodToApi(paymentMethod),
        totalAmount: items.fold<double>(0, (sum, item) => sum + item.lineTotal),
        cartItemCount: cartItemCount,
        durationMs: durationMs,
        syncRetryNotice: syncRetryNotice,
        success: true,
      );
      state = state.copyWith(loading: false, selected: {}, message: message);
      return true;
    } catch (e) {
      final descriptor = _describeSaveError(e);
      final durationMs =
          DateTime.now().difference(checkoutStart).inMilliseconds;
      await _recordCheckoutDiagnostic(
        flow: _checkoutFlow(
          saleType: saleType,
          paymentMethod: paymentMethod,
          payments: payments,
        ),
        saleType: saleType,
        paymentMethod: paymentMethodToApi(paymentMethod),
        totalAmount: state.selected.entries.fold<double>(0, (sum, entry) {
          try {
            final product = _findProduct(entry.key);
            return sum + (entry.value * product.sellPrice);
          } catch (_) {
            return sum;
          }
        }),
        cartItemCount: state.selected.values.fold<int>(
          0,
          (sum, qty) => sum + qty,
        ),
        durationMs: durationMs,
        syncRetryNotice: false,
        success: false,
        errorCode: descriptor.code,
        errorMessage: descriptor.message,
      );
      state = state.copyWith(loading: false, message: descriptor.message);
      return false;
    }
  }

  ({String code, String message}) _describeSaveError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('insufficient stock')) {
      return (
        code: 'insufficient_stock',
        message: 'Sale could not be saved: insufficient stock.',
      );
    }
    if (lower.contains('customer') && lower.contains('required')) {
      return (
        code: 'customer_required',
        message: 'Sale could not be saved: select a customer for credit.',
      );
    }
    if (lower.contains('duplicate phone')) {
      return (
        code: 'customer_phone_ambiguous',
        message:
            'Multiple customers found with this phone number. Merge duplicates first.',
      );
    }
    if (lower.contains('multiple customers found')) {
      return (
        code: 'customer_ambiguous',
        message:
            'Multiple customers found with this name. Use customer picker or phone number.',
      );
    }
    if (lower.contains('product missing') ||
        lower.contains('product not found')) {
      return (
        code: 'product_missing',
        message:
            'Sale could not be saved: one or more products are unavailable.',
      );
    }
    return (
      code: 'save_failed',
      message: 'Sale could not be saved. Please review items and try again.',
    );
  }

  String _checkoutFlow({
    required String saleType,
    required PaymentMethod paymentMethod,
    required List<SalePaymentInput> payments,
  }) {
    if (payments.length > 1 || paymentMethod == PaymentMethod.mixed) {
      return 'advanced_mixed';
    }
    if (saleType == 'CREDIT' || paymentMethod == PaymentMethod.credit) {
      return 'quick_credit';
    }
    return 'quick_cash';
  }

  Future<void> _recordCheckoutDiagnostic({
    required String flow,
    required String saleType,
    required String paymentMethod,
    required double totalAmount,
    required int cartItemCount,
    required int durationMs,
    required bool syncRetryNotice,
    required bool success,
    String? errorCode,
    String? errorMessage,
  }) async {
    try {
      final db = await ref.read(localDatabaseProvider).database;
      final storeId = await ref.read(preferencesProvider).getActiveStoreId();
      await db.insert('checkout_diagnostics', {
        'store_id': storeId,
        'flow': flow,
        'sale_type': saleType,
        'payment_method': paymentMethod,
        'total_amount': totalAmount,
        'cart_item_count': cartItemCount,
        'duration_ms': durationMs,
        'sync_retry_notice': syncRetryNotice ? 1 : 0,
        'success': success ? 1 : 0,
        'error_code': errorCode,
        'error_message': errorMessage,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Never block checkout on local diagnostics write failure.
    }
  }

  Product _findProduct(String id) {
    for (final product in state.products) {
      if (product.id == id) return product;
    }
    for (final product in state.recentProducts) {
      if (product.id == id) return product;
    }
    throw StateError('Product not found');
  }

  Future<String> _resolveOrCreateCustomerId({
    required String customerName,
    String? phone,
  }) async {
    final cleanName = customerName.trim();
    final cleanPhone = phone?.trim();
    final normalizedName = cleanName.toLowerCase();
    final hasPhone = cleanPhone != null && cleanPhone.isNotEmpty;
    final customers = await _customersRepository.listCustomers();

    if (hasPhone) {
      final phoneMatches =
          customers
              .where((c) => (c.phone?.trim() ?? '') == cleanPhone)
              .toList();
      if (phoneMatches.length == 1) {
        final existing = phoneMatches.first;
        if (existing.name.trim() != cleanName) {
          // Phone is the identity key for credit. Reuse the same customer id and
          // refresh name to what user entered to avoid duplicate-credit splits.
          await _customersRepository.updateCustomer(
            Customer(
              id: existing.id,
              name: cleanName,
              phone: existing.phone,
              address: existing.address,
              notes: existing.notes,
              balance: existing.balance,
              createdAt: existing.createdAt,
              isDeleted: existing.isDeleted,
            ),
          );
        }
        return existing.id;
      }
      if (phoneMatches.length > 1) {
        final narrowed =
            phoneMatches
                .where((c) => c.name.trim().toLowerCase() == normalizedName)
                .toList();
        if (narrowed.length == 1) return narrowed.first.id;
        throw StateError(
          'Duplicate phone customer match; multiple customers found.',
        );
      }

      // Phone is provided but does not match an existing customer: create a new
      // customer record keyed by this phone to avoid accidental same-name merge.
      return _customersRepository.addCustomer(
        name: cleanName,
        phone: cleanPhone,
      );
    }

    final nameMatches =
        customers
            .where((c) => c.name.trim().toLowerCase() == normalizedName)
            .toList();
    if (nameMatches.length == 1) {
      return nameMatches.first.id;
    }
    if (nameMatches.length > 1) {
      throw StateError('Multiple customers found with same name');
    }

    return _customersRepository.addCustomer(name: cleanName, phone: null);
  }
}
