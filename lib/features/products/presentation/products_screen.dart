import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/web_safe_image.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/product.dart';
import '../providers/products_provider.dart';
import '../services/low_stock_service.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, isAdmin),
          const SizedBox(height: 24),
          Expanded(
            child: productsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => EmptyStateWidget(
                message: '${AppStrings.error}: $e',
                icon: Icons.error_outline,
              ),
              data: (products) => products.isEmpty
                  ? EmptyStateWidget(
                      message: 'لا توجد منتجات',
                      icon: Icons.inventory_2_outlined,
                      actionLabel: AppStrings.addProduct,
                      onAction: () => _showProductForm(context, ref, null),
                    )
                  : _ProductGrid(products: products),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isAdmin) {
    return PageHeader(
      title: AppStrings.productsTitle,
      subtitle: 'إدارة قائمة المنتجات والمخزون',
      action: isAdmin
          ? Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleSendRestockEmail(context, ref),
                  icon: const Icon(Icons.forward_to_inbox_rounded, size: 18),
                  label: const Text('إرسال طلب إعادة المخزون'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showProductForm(context, ref, null),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(AppStrings.addProduct),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _handleSendRestockEmail(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جارٍ حساب المخزون وإرسال البريد...')),
      );

      final service = ref.read(lowStockServiceProvider);
      await service.sendRestockEmail();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال تنبيه نقص المخزون بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showProductForm(
      BuildContext context, WidgetRef ref, Product? product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(product: product),
    );
  }
}

// ── Product Grid ──────────────────────────────────────────────────────────────

class _ProductGrid extends ConsumerWidget {
  final List<Product> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) => ProductCard(
        product: products[i],
        showAdminActions: true,
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final bool showAdminActions;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.showAdminActions = false,
    this.onTap,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(
            color: _hovered ? AppColors.primary.withValues(alpha: 0.5) : AppColors.divider,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.cardBorderRadius)),
                  child: p.imageUrl.isNotEmpty
                      ? WebSafeImage(
                          url: p.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: () => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(p.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          p.isInStock
                              ? Icons.inventory_2_outlined
                              : Icons.remove_shopping_cart_outlined,
                          size: 12,
                          color: p.isInStock
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.isInStock
                              ? '${p.stockQty} ${AppStrings.stockUnits}'
                              : AppStrings.outOfStock,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.isInStock
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    if (widget.showAdminActions) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    ProductFormDialog(product: p),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text(AppStrings.edit),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _confirmDelete(context, ref, p.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text(AppStrings.delete),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Icon(Icons.water_drop_outlined,
          color: AppColors.onSurfaceMuted, size: 48),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteProduct),
        content: const Text(AppStrings.deleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.deleteConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(productsNotifierProvider.notifier).deleteProduct(id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }
}

// ── Product Form Dialog ───────────────────────────────────────────────────────

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _existingImageUrl;
  bool _isLoading = false;
  String? _uploadStatus; // null = no status, 'uploading', 'success', 'error'

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _stockController =
        TextEditingController(text: p != null ? p.stockQty.toString() : '0');
    _existingImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // Required for web: loads file bytes into memory
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes!;
        _selectedImageName = result.files.single.name;
        _uploadStatus = 'selected';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('تم اختيار الصورة بنجاح ✓'),
            ],
          ),
          backgroundColor: Color(0xFF2ECC71),
          duration: Duration(seconds: 2),
        ));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productsRepositoryProvider);
      String imageUrl = _existingImageUrl ?? '';

      // Upload new image if selected
      if (_selectedImageBytes != null) {
        setState(() => _uploadStatus = 'uploading');
        try {
          final tempId =
              DateTime.now().millisecondsSinceEpoch.toString();
          imageUrl = await repo.uploadProductImageBytes(
              _selectedImageBytes!, tempId, _selectedImageName ?? 'image.png');
          setState(() => _uploadStatus = 'success');
        } catch (e) {
          setState(() {
            _uploadStatus = 'error';
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('فشل رفع الصورة: $e'),
              backgroundColor: AppColors.error,
            ));
          }
          return;
        }
      }

      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        imageUrl: imageUrl,
        stockQty: int.tryParse(_stockController.text) ?? 0,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await ref
            .read(productsNotifierProvider.notifier)
            .updateProduct(product);
      } else {
        await ref
            .read(productsNotifierProvider.notifier)
            .addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ المنتج بنجاح ✓'),
          backgroundColor: Color(0xFF2ECC71),
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.error}: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxWidth: AppConstants.dialogMaxWidth, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing
                      ? AppStrings.editProduct
                      : AppStrings.addProduct,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildField(_nameController, AppStrings.productName,
                            Icons.label_outline),
                        const SizedBox(height: 12),
                        _buildField(_descController,
                            AppStrings.productDescription, Icons.notes_rounded,
                            maxLines: 3),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                  _priceController,
                                  AppStrings.productPrice,
                                  Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return AppStrings.requiredField;
                                }
                                if (double.tryParse(v) == null) {
                                  return 'أدخل رقماً صحيحاً';
                                }
                                return null;
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                _stockController,
                                AppStrings.productStock,
                                Icons.inventory_2_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Image picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: _selectedImageBytes != null
                                      ? AppColors.success.withValues(alpha: 0.08)
                                      : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedImageBytes != null
                                        ? AppColors.success
                                        : AppColors.divider,
                                    width: _selectedImageBytes != null ? 2 : 1,
                                  ),
                                ),
                                child: _selectedImageBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.memory(_selectedImageBytes!,
                                            fit: BoxFit.cover,
                                            width: double.infinity),
                                      )
                                    : _existingImageUrl != null &&
                                            _existingImageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                            child: WebSafeImage(
                                                url: _existingImageUrl!,
                                                fit: BoxFit.cover,
                                                width: double.infinity),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.add_photo_alternate,
                                                  color: AppColors.onSurfaceMuted,
                                                  size: 36),
                                              SizedBox(height: 8),
                                              Text(AppStrings.selectImage,
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.onSurfaceMuted,
                                                      fontSize: 13)),
                                            ],
                                          ),
                              ),
                              // Status badge shown based on upload state
                              if (_selectedImageBytes != null || _uploadStatus == 'uploading')
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _uploadStatus == 'uploading'
                                          ? AppColors.warning
                                          : _uploadStatus == 'error'
                                              ? AppColors.error
                                              : AppColors.success,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_uploadStatus == 'uploading')
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        else
                                          Icon(
                                            _uploadStatus == 'error'
                                                ? Icons.error
                                                : Icons.check_circle,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _uploadStatus == 'uploading'
                                              ? 'جاري الرفع...'
                                              : _uploadStatus == 'error'
                                                  ? 'فشل الرفع'
                                                  : 'تم اختيار الصورة',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary))
                          : Text(AppStrings.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceMuted, size: 18),
      ),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty)
              ? AppStrings.requiredField
              : null,
    );
  }
}
