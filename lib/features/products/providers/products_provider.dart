import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/products_repository.dart';
import '../../../models/product.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository();
});

/// Live stream of all products.
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).watchProducts();
});

/// Products notifier handles add/edit/delete operations.
class ProductsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addProduct(Product product) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productsRepositoryProvider).addProduct(product),
    );
  }

  Future<void> updateProduct(Product product) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productsRepositoryProvider).updateProduct(product),
    );
  }

  Future<void> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productsRepositoryProvider).deleteProduct(productId),
    );
  }
}

final productsNotifierProvider =
    AsyncNotifierProvider<ProductsNotifier, void>(ProductsNotifier.new);
