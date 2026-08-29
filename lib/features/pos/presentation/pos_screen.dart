import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/web_safe_image.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/orders/data/orders_repository.dart';
import '../../../features/invoice/pdf_invoice_generator.dart';
import '../../../models/order.dart';
import '../providers/cart_provider.dart';
import '../../products/presentation/products_screen.dart';
import '../../products/providers/products_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerDetailsController = TextEditingController();
  String _searchQuery = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final cart = ref.watch(cartProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: AppStrings.posTitle,
            subtitle: 'أضف المنتجات وأتمم الطلب',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product Panel ──────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppColors.onSurface),
                        decoration: const InputDecoration(
                          hintText: AppStrings.searchProducts,
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.onSurfaceMuted, size: 20),
                          isDense: true,
                        ),
                        onChanged: (q) =>
                            setState(() => _searchQuery = q.toLowerCase()),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: productsAsync.when(
                          loading: () => const LoadingWidget(),
                          error: (e, _) => EmptyStateWidget(
                              message: '${AppStrings.error}: $e'),
                          data: (products) {
                            final filtered = products
                                .where((p) =>
                                    p.name
                                        .toLowerCase()
                                        .contains(_searchQuery) &&
                                    p.isInStock)
                                .toList();
                            if (filtered.isEmpty) {
                              return const EmptyStateWidget(
                                message: 'لا توجد منتجات متوفرة',
                                icon: Icons.inventory_2_outlined,
                              );
                            }
                            return GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final p = filtered[i];
                                return ProductCard(
                                  product: p,
                                  showAdminActions: false,
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .addProduct(p),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // ── Cart Panel ─────────────────────────────────────────────
                Container(
                  width: 340,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardBorderRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cart header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(
                                  AppConstants.cardBorderRadius)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${AppStrings.cart} (${cart.items.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            if (cart.items.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    ref.read(cartProvider.notifier).clear(),
                                child: const Text(AppStrings.clearCart,
                                    style: TextStyle(
                                        color: AppColors.error, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      // Cart items
                      Expanded(
                        child: cart.items.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined,
                                        size: 48,
                                        color: AppColors.onSurfaceMuted),
                                    SizedBox(height: 12),
                                    Text(AppStrings.emptyCart,
                                        style: TextStyle(
                                            color: AppColors.onSurfaceMuted,
                                            fontSize: 14)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: cart.items.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 12),
                                itemBuilder: (ctx, i) =>
                                    _CartItemTile(item: cart.items[i]),
                              ),
                      ),
                      const Divider(height: 1),
                      // Customer info + total + submit
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _customerNameController,
                              style: const TextStyle(
                                  color: AppColors.onSurface, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: AppStrings.customerName,
                                prefixIcon: Icon(Icons.person_outline,
                                    size: 16,
                                    color: AppColors.onSurfaceMuted),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _customerDetailsController,
                              style: const TextStyle(
                                  color: AppColors.onSurface, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: AppStrings.customerDetails,
                                prefixIcon: Icon(Icons.phone_outlined,
                                    size: 16,
                                    color: AppColors.onSurfaceMuted),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(AppStrings.grandTotal,
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  CurrencyFormatter.format(cart.grandTotal),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: cart.items.isEmpty || _isSubmitting
                                    ? null
                                    : _submitOrder,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.onPrimary))
                                    : const Icon(Icons.check_circle_outline,
                                        size: 18),
                                label: const Text(AppStrings.submitOrder,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOrder() async {
    final customerName = _customerNameController.text.trim();
    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(AppStrings.customerNameRequired),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final currentUser = ref.read(currentAppUserProvider).valueOrNull;
      final ordersRepo = OrdersRepository();
      final invoiceId = await ordersRepo.generateInvoiceId();

      final order = Order(
        id: invoiceId,
        createdByUid: currentUser?.uid ?? '',
        createdByName: currentUser?.name ?? '',
        customerName: customerName,
        customerDetails: _customerDetailsController.text.trim(),
        orderItems: cart.items.map((i) => i.toOrderItem()).toList(),
        totalAmount: cart.grandTotal,
        createdAt: DateTime.now(),
      );

      final stockItems = cart.items
          .map((i) =>
              {'productId': i.product.id, 'quantity': i.quantity})
          .toList();

      await ordersRepo.createOrder(order, stockItems);

      // ── Order saved successfully ──────────────────────────────────────
      // Clear cart and customer fields BEFORE attempting PDF so the UI
      // is always reset regardless of what happens with the printer.
      ref.read(cartProvider.notifier).clear();
      _customerNameController.clear();
      _customerDetailsController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(AppStrings.orderSuccess),
          backgroundColor: AppColors.success,
        ));
      }

      // ── Generate and show PDF invoice (non-blocking for the order) ────
      // If PDF printing fails (e.g. no printer on Windows) we show a
      // separate warning — the order is already saved in Firestore.
      try {
        await PdfInvoiceGenerator.printInvoice(order);
      } catch (pdfError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تعذّر فتح الفاتورة: $pdfError'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.orderError}: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ── Cart Item Tile ────────────────────────────────────────────────────────────

class _CartItemTile extends ConsumerStatefulWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  ConsumerState<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<_CartItemTile> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController =
        TextEditingController(text: '${widget.item.quantity}');
  }

  @override
  void didUpdateWidget(_CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity) {
      final newText = '${widget.item.quantity}';
      if (_qtyController.text != newText) {
        _qtyController.text = newText;
        _qtyController.selection = TextSelection.fromPosition(
            TextPosition(offset: newText.length));
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _resetInvalidQty() {
    final qty = int.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      _qtyController.text = '${widget.item.quantity}';
      // Unfocus keyboard
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.read(cartProvider.notifier);

    return Row(
      children: [
        // Product image thumbnail
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.item.product.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: WebSafeImage(
                    url: widget.item.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: () => const Icon(
                        Icons.water_drop_outlined,
                        color: AppColors.onSurfaceMuted,
                        size: 20),
                  ),
                )
              : const Icon(Icons.water_drop_outlined,
                  color: AppColors.onSurfaceMuted, size: 20),
        ),
        const SizedBox(width: 10),
        // Name + price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.product.name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                CurrencyFormatter.format(widget.item.subtotal),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        // Quantity controls
        Row(
          children: [
            _QtyButton(
              icon: Icons.remove,
              onTap: () => cartNotifier.updateQuantity(
                  widget.item.product.id, widget.item.quantity - 1),
            ),
            // Manual quantity input
            SizedBox(
              width: 42,
              height: 28,
              child: TextField(
                controller: _qtyController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                        color: AppColors.divider, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                        color: AppColors.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  final qty = int.tryParse(val);
                  if (qty != null && qty > 0) {
                    cartNotifier.updateQuantity(
                        widget.item.product.id, qty);
                  }
                },
                onSubmitted: (_) => _resetInvalidQty(),
                onEditingComplete: _resetInvalidQty,
              ),
            ),
            _QtyButton(
              icon: Icons.add,
              onTap: () => cartNotifier.updateQuantity(
                  widget.item.product.id, widget.item.quantity + 1),
            ),
          ],
        ),
        const SizedBox(width: 4),
        // Remove (red)
        InkWell(
          onTap: () => cartNotifier.removeProduct(widget.item.product.id),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.close_rounded,
                size: 18, color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: AppColors.onSurface),
      ),
    );
  }
}
