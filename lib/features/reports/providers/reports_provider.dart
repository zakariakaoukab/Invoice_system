import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/providers/orders_provider.dart';
import '../../../models/order.dart' as app_order;

// 1. Enum for Date Range
enum ReportDateRange {
  last7Days,
  last30Days,
  thisMonth,
  allTime,
  custom,
}

// 2. Notifier for selected date range
class ReportDateRangeState {
  final ReportDateRange type;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const ReportDateRangeState({
    required this.type,
    this.customStartDate,
    this.customEndDate,
  });
}

class ReportDateRangeNotifier extends Notifier<ReportDateRangeState> {
  @override
  ReportDateRangeState build() {
    return const ReportDateRangeState(type: ReportDateRange.last30Days);
  }

  void setType(ReportDateRange type) {
    state = ReportDateRangeState(type: type, customStartDate: state.customStartDate, customEndDate: state.customEndDate);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = ReportDateRangeState(
      type: ReportDateRange.custom,
      customStartDate: start,
      customEndDate: end,
    );
  }
}

final reportDateRangeProvider = NotifierProvider<ReportDateRangeNotifier, ReportDateRangeState>(ReportDateRangeNotifier.new);

// 3. Provider that filters orders based on date range
final reportOrdersProvider = Provider<List<app_order.Order>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  final dateRange = ref.watch(reportDateRangeProvider);

  return ordersAsync.maybeWhen(
    data: (orders) {
      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;

      switch (dateRange.type) {
        case ReportDateRange.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case ReportDateRange.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case ReportDateRange.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case ReportDateRange.allTime:
          break; // null start/end means all time
        case ReportDateRange.custom:
          startDate = dateRange.customStartDate;
          if (dateRange.customEndDate != null) {
            // Include the whole end day
            endDate = DateTime(
              dateRange.customEndDate!.year,
              dateRange.customEndDate!.month,
              dateRange.customEndDate!.day,
              23, 59, 59,
            );
          }
          break;
      }

      return orders.where((o) {
        if (startDate != null && o.createdAt.isBefore(startDate)) return false;
        if (endDate != null && o.createdAt.isAfter(endDate)) return false;
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

// 4. Metrics Providers
final reportTotalRevenueProvider = Provider<double>((ref) {
  final orders = ref.watch(reportOrdersProvider);
  return orders.fold(0.0, (sum, order) => sum + order.totalAmount);
});

final reportTotalOrdersProvider = Provider<int>((ref) {
  final orders = ref.watch(reportOrdersProvider);
  return orders.length;
});

final reportAvgOrderValueProvider = Provider<double>((ref) {
  final orders = ref.watch(reportOrdersProvider);
  if (orders.isEmpty) return 0.0;
  final revenue = ref.watch(reportTotalRevenueProvider);
  return revenue / orders.length;
});

// 5. Line Chart Data (Sales by Date)
final reportSalesTrendProvider = Provider<Map<DateTime, double>>((ref) {
  final orders = ref.watch(reportOrdersProvider);
  final Map<DateTime, double> salesByDate = {};

  for (final order in orders) {
    // Normalize date to day
    final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
    salesByDate[date] = (salesByDate[date] ?? 0) + order.totalAmount;
  }

  return salesByDate;
});

// 6. Pie Chart Data (Sales by Product)
final reportProductBreakdownProvider = Provider<Map<String, double>>((ref) {
  final orders = ref.watch(reportOrdersProvider);
  final Map<String, double> salesByProduct = {};

  for (final order in orders) {
    for (final item in order.orderItems) {
      salesByProduct[item.productName] = (salesByProduct[item.productName] ?? 0) + (item.unitPrice * item.quantity);
    }
  }

  // Sort by revenue descending
  var sortedEntries = salesByProduct.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  return Map.fromEntries(sortedEntries);
});
