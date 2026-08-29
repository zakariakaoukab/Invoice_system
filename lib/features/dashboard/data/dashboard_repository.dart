import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../core/constants/app_constants.dart';
import '../../../models/order.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns orders created in the current calendar month.
  Future<List<Order>> fetchOrdersThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final snap = await _firestore
        .collection(AppConstants.ordersCollection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .get();

    return snap.docs.map(Order.fromFirestore).toList();
  }

  /// Returns all orders for the past [months] months grouped by month.
  /// Used for the sales chart.
  Future<Map<String, double>> fetchMonthlySales({int months = 6}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);

    final snap = await _firestore
        .collection(AppConstants.ordersCollection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('createdAt')
        .get();

    final orders = snap.docs.map(Order.fromFirestore).toList();
    final Map<String, double> monthly = {};

    for (final order in orders) {
      final key =
          '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + order.totalAmount;
    }
    return monthly;
  }

  /// Returns top selling products by total quantity sold.
  Future<List<MapEntry<String, int>>> fetchTopProducts({int limit = 5}) async {
    final snap = await _firestore
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(200) // scan last 200 orders for performance
        .get();

    final orders = snap.docs.map(Order.fromFirestore).toList();
    final Map<String, int> counts = {};

    for (final order in orders) {
      for (final item in order.orderItems) {
        counts[item.productName] =
            (counts[item.productName] ?? 0) + item.quantity;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).toList();
  }
}
