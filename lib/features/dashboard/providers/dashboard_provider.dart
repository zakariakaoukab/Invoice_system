import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../../../models/order.dart' as app_order;

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

// ── Monthly Orders ────────────────────────────────────────────────────────────

final monthlyOrdersProvider = FutureProvider<List<app_order.Order>>((ref) async {
  return ref.read(dashboardRepositoryProvider).fetchOrdersThisMonth();
});

// ── Monthly Sales (DH) ────────────────────────────────────────────────────────

final monthlySalesProvider = Provider<double>((ref) {
  return ref.watch(monthlyOrdersProvider).maybeWhen(
        data: (orders) =>
            orders.fold(0.0, (sum, o) => sum + o.totalAmount),
        orElse: () => 0.0,
      );
});

// ── Order count ────────────────────────────────────────────────────────────────

final monthlyOrderCountProvider = Provider<int>((ref) {
  return ref.watch(monthlyOrdersProvider).maybeWhen(
        data: (orders) => orders.length,
        orElse: () => 0,
      );
});

// ── Average Order Value ───────────────────────────────────────────────────────

final avgOrderValueProvider = Provider<double>((ref) {
  return ref.watch(monthlyOrdersProvider).maybeWhen(
        data: (orders) {
          if (orders.isEmpty) return 0.0;
          final total =
              orders.fold(0.0, (sum, o) => sum + o.totalAmount);
          return total / orders.length;
        },
        orElse: () => 0.0,
      );
});

// ── Sales Chart Data (last 6 months) ─────────────────────────────────────────

final monthlySalesChartProvider =
    FutureProvider<Map<String, double>>((ref) async {
  return ref.read(dashboardRepositoryProvider).fetchMonthlySales(months: 6);
});

// ── Top Products ──────────────────────────────────────────────────────────────

final topProductsProvider =
    FutureProvider<List<MapEntry<String, int>>>((ref) async {
  return ref.read(dashboardRepositoryProvider).fetchTopProducts(limit: 5);
});
