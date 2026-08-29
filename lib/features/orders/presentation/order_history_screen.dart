import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/order.dart';
import '../providers/orders_provider.dart';
import '../../invoice/pdf_invoice_generator.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() =>
      _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final orders = ref.watch(filteredOrdersProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: AppStrings.ordersTitle,
            subtitle: 'سجل جميع الطلبات والفواتير',
          ),
          const SizedBox(height: 20),
          // Filters bar
          _FiltersBar(
            isAdmin: isAdmin,
            searchController: _searchController,
          ),
          const SizedBox(height: 16),
          // Table
          Expanded(
            child: ref.watch(ordersStreamProvider).isLoading
                ? const LoadingWidget()
                : orders.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد طلبات',
                        icon: Icons.receipt_long_outlined,
                      )
                    : _OrdersTable(orders: orders, isAdmin: isAdmin),
          ),
        ],
      ),
    );
  }
}

// ── Filters Bar ───────────────────────────────────────────────────────────────

class _FiltersBar extends ConsumerWidget {
  final bool isAdmin;
  final TextEditingController searchController;

  const _FiltersBar({
    required this.isAdmin,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterNotifier = ref.read(orderFilterProvider.notifier);
    final filter = ref.watch(orderFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search field
          SizedBox(
            width: 260,
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppStrings.searchOrders,
                prefixIcon: const Icon(Icons.search, size: 18,
                    color: AppColors.onSurfaceMuted),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: filterNotifier.setSearch,
            ),
          ),
          // From date
          _DatePickerButton(
            label: filter.fromDate != null
                ? 'من: ${DateFormatter.formatDate(filter.fromDate!)}'
                : AppStrings.from,
            onPick: (date) => filterNotifier.setFromDate(date),
            context: context,
          ),
          // To date
          _DatePickerButton(
            label: filter.toDate != null
                ? 'إلى: ${DateFormatter.formatDate(filter.toDate!)}'
                : AppStrings.to,
            onPick: (date) => filterNotifier.setToDate(date),
            context: context,
          ),
          // Clear button
          if (filter.fromDate != null ||
              filter.toDate != null ||
              filter.searchQuery.isNotEmpty ||
              filter.cashierUid != null)
            TextButton.icon(
              onPressed: () {
                filterNotifier.clear();
                searchController.clear();
              },
              icon: const Icon(Icons.clear_rounded,
                  size: 16, color: AppColors.onSurfaceMuted),
              label: const Text(AppStrings.clearFilter,
                  style: TextStyle(color: AppColors.onSurfaceMuted)),
            ),
        ],
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final Function(DateTime?) onPick;
  final BuildContext context;

  const _DatePickerButton({
    required this.label,
    required this.onPick,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        onPick(picked);
      },
      icon: const Icon(Icons.calendar_today_outlined, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

// ── Orders Table ──────────────────────────────────────────────────────────────

class _OrdersTable extends StatelessWidget {
  final List<Order> orders;
  final bool isAdmin;

  const _OrdersTable({required this.orders, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 20,
            columns: [
              const DataColumn(label: Text(AppStrings.invoiceNumber)),
              const DataColumn(label: Text(AppStrings.dateTime)),
              const DataColumn(label: Text(AppStrings.customerNameCol)),
              if (isAdmin)
                const DataColumn(label: Text(AppStrings.createdBy)),
              const DataColumn(label: Text(AppStrings.totalAmount)),
              const DataColumn(label: Text(AppStrings.actions)),
            ],
            rows: orders.map((order) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    order.id,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  )),
                  DataCell(Text(
                    DateFormatter.formatDateTime(order.createdAt),
                    style: const TextStyle(fontSize: 13),
                  )),
                  DataCell(Text(
                    order.customerName,
                    style: const TextStyle(fontSize: 13),
                  )),
                  if (isAdmin)
                    DataCell(Text(
                      order.createdByName,
                      style: const TextStyle(fontSize: 13),
                    )),
                  DataCell(Text(
                    CurrencyFormatter.format(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                      fontSize: 13,
                    ),
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.visibility_outlined,
                        tooltip: AppStrings.viewDetails,
                        onTap: () =>
                            _showOrderDetails(context, order, isAdmin),
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.print_outlined,
                        tooltip: AppStrings.printInvoice,
                        color: AppColors.primary,
                        onTap: () async {
                          try {
                            await PdfInvoiceGenerator.printInvoice(order);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تعذّر فتح الفاتورة: $e'),
                                backgroundColor: AppColors.warning,
                              ));
                            }
                          }
                        },
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order, bool isAdmin) {
    showDialog(
      context: context,
      builder: (_) => OrderDetailsDialog(order: order, isAdmin: isAdmin),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (color ?? AppColors.onSurfaceMuted).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              size: 16, color: color ?? AppColors.onSurfaceMuted),
        ),
      ),
    );
  }
}

// ── Order Details Dialog ──────────────────────────────────────────────────────

class OrderDetailsDialog extends StatelessWidget {
  final Order order;
  final bool isAdmin;

  const OrderDetailsDialog(
      {super.key, required this.order, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.orderDetails} — ${order.id}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatDateTime(order.createdAt),
                          style: const TextStyle(
                              color: AppColors.onSurfaceMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Customer + Cashier info
              _InfoRow(label: AppStrings.customerNameCol,
                  value: order.customerName),
              if (order.customerDetails.isNotEmpty)
                _InfoRow(
                    label: 'تفاصيل الزبون', value: order.customerDetails),
              if (isAdmin)
                _InfoRow(label: AppStrings.createdBy,
                    value: order.createdByName),
              const Divider(height: 24),
              // Items table
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1.5),
                      3: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                            color: AppColors.surfaceElevated),
                        children: [
                          AppStrings.productName,
                          AppStrings.quantity,
                          AppStrings.unitPrice,
                          AppStrings.subtotal,
                        ]
                            .map((h) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: Text(h,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.onSurfaceMuted)),
                                ))
                            .toList(),
                      ),
                      ...order.orderItems.map((item) => TableRow(
                            children: [
                              item.productName,
                              '${item.quantity}',
                              CurrencyFormatter.format(item.unitPrice),
                              CurrencyFormatter.format(item.subtotal),
                            ]
                                .map((v) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 10),
                                      child: Text(v,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.onSurface)),
                                    ))
                                .toList(),
                          )),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.grandTotal,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    CurrencyFormatter.format(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.close),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await PdfInvoiceGenerator.printInvoice(order);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('تعذّر فتح الفاتورة: $e'),
                            backgroundColor: AppColors.warning,
                          ));
                        }
                      }
                    },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text(AppStrings.printInvoice),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.onSurfaceMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
