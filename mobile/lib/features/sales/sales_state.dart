import '../products/domain/product.dart';

class SalesState {
  SalesState({
    this.loading = false,
    this.search = '',
    this.products = const [],
    this.recentProducts = const [],
    this.selected = const {},
    this.message,
  });

  final bool loading;
  final String search;
  final List<Product> products;
  final List<Product> recentProducts;
  final Map<String, int> selected;
  final String? message;

  SalesState copyWith({
    bool? loading,
    String? search,
    List<Product>? products,
    List<Product>? recentProducts,
    Map<String, int>? selected,
    String? message,
  }) {
    return SalesState(
      loading: loading ?? this.loading,
      search: search ?? this.search,
      products: products ?? this.products,
      recentProducts: recentProducts ?? this.recentProducts,
      selected: selected ?? this.selected,
      message: message,
    );
  }

  bool get canSave => selected.isNotEmpty;
}
