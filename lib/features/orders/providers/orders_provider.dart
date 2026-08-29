import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/orders_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/order.dart' as app_order;

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository();
});

/// Stream of orders — all for admin, own for standard users.
final ordersStreamProvider = StreamProvider<List<app_order.Order>>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  final repo = ref.watch(ordersRepositoryProvider);
  if (isAdmin) {
    return repo.watchAllOrders();
  }
  final uid = ref.watch(firebaseAuthStateProvider).valueOrNull?.uid ?? '';
  return repo.watchOrdersByUser(uid);
});

// ── Filter state ──────────────────────────────────────────────────────────────

class OrderFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? cashierUid;
  final String searchQuery;

  const OrderFilter({
    this.fromDate,
    this.toDate,
    this.cashierUid,
    this.searchQuery = '',
  });

  OrderFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? cashierUid,
    String? searchQuery,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearCashier = false,
  }) {
    return OrderFilter(
      fromDate: clearFromDate ? null : fromDate ?? this.fromDate,
      toDate: clearToDate ? null : toDate ?? this.toDate,
      cashierUid: clearCashier ? null : cashierUid ?? this.cashierUid,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OrderFilterNotifier extends Notifier<OrderFilter> {
  @override
  OrderFilter build() => const OrderFilter();

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setFromDate(DateTime? date) =>
      state = state.copyWith(fromDate: date, clearFromDate: date == null);

  void setToDate(DateTime? date) =>
      state = state.copyWith(toDate: date, clearToDate: date == null);

  void setCashier(String? uid) =>
      state = state.copyWith(cashierUid: uid, clearCashier: uid == null);

  void clear() => state = const OrderFilter();
}

final orderFilterProvider =
    NotifierProvider<OrderFilterNotifier, OrderFilter>(OrderFilterNotifier.new);

/// Filtered orders derived from the stream + current filter.
final filteredOrdersProvider = Provider<List<app_order.Order>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  final filter = ref.watch(orderFilterProvider);

  return ordersAsync.maybeWhen(
    data: (orders) {
      return orders.where((o) {
        // Date filter
        if (filter.fromDate != null &&
            o.createdAt.isBefore(filter.fromDate!)) return false;
        if (filter.toDate != null) {
          final endOfDay = DateTime(
              filter.toDate!.year, filter.toDate!.month, filter.toDate!.day, 23, 59, 59);
          if (o.createdAt.isAfter(endOfDay)) return false;
        }
        // Cashier filter
        if (filter.cashierUid != null &&
            o.createdByUid != filter.cashierUid) return false;
        // Search filter
        if (filter.searchQuery.isNotEmpty) {
          final q = filter.searchQuery.toLowerCase();
          if (!o.id.toLowerCase().contains(q) &&
              !o.customerName.toLowerCase().contains(q)) return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
