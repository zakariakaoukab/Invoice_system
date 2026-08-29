import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../models/order_item.dart';

/// Cart item: a product + chosen quantity.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  OrderItem toOrderItem() {
    return OrderItem(
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: product.price,
      subtotal: subtotal,
    );
  }
}

/// Cart state.
class CartState {
  final List<CartItem> items;
  final String customerName;
  final String customerDetails;

  const CartState({
    this.items = const [],
    this.customerName = '',
    this.customerDetails = '',
  });

  double get grandTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  CartState copyWith({
    List<CartItem>? items,
    String? customerName,
    String? customerDetails,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      customerDetails: customerDetails ?? this.customerDetails,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addProduct(Product product) {
    final existing =
        state.items.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      final item = state.items[existing];
      // Respect stock limit
      if (item.quantity >= product.stockQty) return;
      final updated = List<CartItem>.from(state.items);
      updated[existing] = item.copyWith(quantity: item.quantity + 1);
      state = state.copyWith(items: updated);
    } else {
      if (product.stockQty == 0) return;
      state = state.copyWith(
          items: [...state.items, CartItem(product: product, quantity: 1)]);
    }
  }

  void removeProduct(String productId) {
    state = state.copyWith(
        items: state.items.where((i) => i.product.id != productId).toList());
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeProduct(productId);
      return;
    }
    final updated = state.items.map((i) {
      if (i.product.id == productId) {
        final clamped = qty.clamp(1, i.product.stockQty);
        return i.copyWith(quantity: clamped);
      }
      return i;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void setCustomerName(String name) =>
      state = state.copyWith(customerName: name);

  void setCustomerDetails(String details) =>
      state = state.copyWith(customerDetails: details);

  void clear() => state = const CartState();
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
