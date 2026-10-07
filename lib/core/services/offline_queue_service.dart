import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../features/orders/data/orders_repository.dart';

class OfflineQueueService {
  static const String _queueKey = 'offline_orders_queue';

  /// Adds an order and its associated stock updates to the offline queue.
  Future<void> enqueueOrder(Order order, List<Map<String, dynamic>> stockItems) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];

    // Convert order to a standard map suitable for JSON
    final orderMap = {
      'id': order.id,
      'createdByUid': order.createdByUid,
      'createdByName': order.createdByName,
      'customerName': order.customerName,
      'customerDetails': order.customerDetails,
      'orderItems': order.orderItems.map((item) => item.toMap()).toList(),
      'totalAmount': order.totalAmount,
      'createdAt': order.createdAt.toIso8601String(),
    };

    final entry = {
      'order': orderMap,
      'stockItems': stockItems,
    };

    queue.add(jsonEncode(entry));
    await prefs.setStringList(_queueKey, queue);
  }

  /// Returns the number of pending orders.
  Future<int> getPendingOrdersCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];
    return queue.length;
  }

  /// Attempts to sync all queued orders to Firebase.
  Future<void> syncPendingOrders() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return; // Still offline
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];

    if (queue.isEmpty) return;

    final repo = OrdersRepository();
    final List<String> remainingQueue = [];
    bool hasErrors = false;

    for (final entryStr in queue) {
      try {
        final entry = jsonDecode(entryStr);
        final orderMap = entry['order'] as Map<String, dynamic>;
        
        final orderItems = (orderMap['orderItems'] as List<dynamic>)
            .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
            .toList();

        final stockItems = (entry['stockItems'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        final order = Order(
          id: orderMap['id'] as String,
          createdByUid: orderMap['createdByUid'] as String,
          createdByName: orderMap['createdByName'] as String,
          customerName: orderMap['customerName'] as String,
          customerDetails: orderMap['customerDetails'] as String,
          orderItems: orderItems,
          totalAmount: (orderMap['totalAmount'] as num).toDouble(),
          createdAt: DateTime.parse(orderMap['createdAt'] as String),
        );

        // Upload to Firebase
        await repo.createOrder(order, stockItems);
      } catch (e) {
        debugPrint('Error syncing order: $e');
        hasErrors = true;
        // Keep in queue if failed
        remainingQueue.add(entryStr);
      }
    }

    await prefs.setStringList(_queueKey, remainingQueue);
  }
}
