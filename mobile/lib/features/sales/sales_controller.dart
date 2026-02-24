import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
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
      try {
        await search('');
      } catch (e) {
        state = state.copyWith(
          loading: false,
          message: 'Failed to load products: $e',
        );
      }
    });
    return SalesState();
  }

  Future<void> search(String query) async {
    try {
      state = state.copyWith(loading: true, search: query, message: null);
      final products = await _productsRepository.searchProducts(query);
      final recentProducts = await _productsRepository.recentProducts();
      state = state.copyWith(
        loading: false,
        products: products,
        recentProducts: recentProducts,
        message: null,
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

  Future<void> saveCashSale() async {
    await _saveSale('CASH');
  }

  Future<void> saveCreditSale() async {
    await _saveSale('CREDIT');
  }

  Future<void> saveCreditSaleWithCustomer({
    required String customerName,
    String? phone,
  }) async {
    final name = customerName.trim();
    if (name.isEmpty) {
      state = state.copyWith(
        message: 'Customer name is required for credit sale.',
      );
      return;
    }
    final customerId = await _customersRepository.addCustomer(
      name: name,
      phone: phone?.trim().isEmpty ?? true ? null : phone?.trim(),
    );
    await _saveSale('CREDIT', customerId: customerId);
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

  Future<void> _saveSale(String saleType, {String? customerId}) async {
    if (!state.canSave) {
      state = state.copyWith(message: 'Please add at least one product.');
      return;
    }

    try {
      state = state.copyWith(loading: true, message: null);
      final items = <SaleItemInput>[];
      for (final entry in state.selected.entries) {
        final product = _findProduct(entry.key);
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
          paymentMethod:
              saleType == 'CREDIT' ? PaymentMethod.credit : PaymentMethod.cash,
          customerId: customerId,
          items: items,
        ),
      );
      final localeCode = ref.read(localeControllerProvider).languageCode;
      await ref
          .read(syncManagerProvider)
          .processPendingSync(localeCode: localeCode);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(customersListProvider);
      ref.invalidate(expensesListProvider);

      state = state.copyWith(
        loading: false,
        selected: {},
        message: 'Sale saved successfully.',
      );
      await search(state.search);
    } catch (e) {
      state = state.copyWith(loading: false, message: e.toString());
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
}
