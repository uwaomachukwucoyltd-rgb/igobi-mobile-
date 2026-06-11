import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../checkout/data/checkout_quote_models.dart';
import '../marketplace/marketplace_data.dart';

class CartItem {
  const CartItem({required this.product, required this.qty});
  final Product product;
  final int qty;

  int get subtotalNgn => product.priceNgn * qty;

  CartItem copyWith({int? qty}) => CartItem(product: product, qty: qty ?? this.qty);
}

class CartState {
  const CartState({this.items = const []});
  final List<CartItem> items;

  int get count => items.fold(0, (a, b) => a + b.qty);
  int get totalNgn => items.fold(0, (a, b) => a + b.subtotalNgn);
  bool get isEmpty => items.isEmpty;

  /// All items are PHYSICAL — checkout pays the vendor directly (no escrow).
  bool get isAllPhysical =>
      items.isNotEmpty &&
      items.every((i) => i.product.productType == ProductType.physical);

  /// All items are SERVICE — checkout funds an escrow held until the buyer
  /// confirms delivery.
  bool get isAllService =>
      items.isNotEmpty &&
      items.every((i) => i.product.productType == ProductType.service);

  /// Mixed cart: services and physical goods cannot check out together.
  /// We block this at the UI level — the buyer must remove one type.
  bool get isMixedTypes => !isAllPhysical && !isAllService && items.isNotEmpty;

  /// Fee category, derived from the first item's category. All items in a
  /// valid (non-mixed) cart roll up to the same fee category — see
  /// `isMixedFeeCategories` below to detect violations.
  FeeCategory? get feeCategory {
    if (items.isEmpty) return null;
    return feeCategoryFromProductCategory(items.first.product.category);
  }

  /// True when items span more than one fee category. Blocks checkout at
  /// the cart-sheet level with a "items must check out separately" hint.
  /// Distinct from `isMixedTypes` (which is the broader physical-vs-service
  /// gate that already exists).
  bool get isMixedFeeCategories {
    if (items.length < 2) return false;
    final first = feeCategoryFromProductCategory(items.first.product.category);
    return items.any(
      (i) => feeCategoryFromProductCategory(i.product.category) != first,
    );
  }
}

class CartController extends StateNotifier<CartState> {
  CartController() : super(const CartState());

  void add(Product product) {
    final idx = state.items.indexWhere((i) => i.product.id == product.id);
    final next = [...state.items];
    if (idx >= 0) {
      next[idx] = next[idx].copyWith(qty: next[idx].qty + 1);
    } else {
      next.add(CartItem(product: product, qty: 1));
    }
    state = CartState(items: next);
  }

  void increment(String productId) {
    final next = [...state.items];
    final idx = next.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    next[idx] = next[idx].copyWith(qty: next[idx].qty + 1);
    state = CartState(items: next);
  }

  void decrement(String productId) {
    final next = [...state.items];
    final idx = next.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    if (next[idx].qty <= 1) {
      next.removeAt(idx);
    } else {
      next[idx] = next[idx].copyWith(qty: next[idx].qty - 1);
    }
    state = CartState(items: next);
  }

  void remove(String productId) {
    state = CartState(items: state.items.where((i) => i.product.id != productId).toList());
  }

  void clear() {
    state = const CartState();
  }
}

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) => CartController());
