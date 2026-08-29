import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../core/constants/app_constants.dart';
import '../../../models/order.dart';

class OrdersRepository {
  final FirebaseFirestore _firestore;

  OrdersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of all orders (admin view) — newest first.
  Stream<List<Order>> watchAllOrders() {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Order.fromFirestore).toList());
  }

  /// Stream of orders created by a specific user.
  Stream<List<Order>> watchOrdersByUser(String uid) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('createdByUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Order.fromFirestore).toList());
  }

  /// Generates the next invoice ID.
  ///
  /// Uses a simple get → increment → set pattern instead of
  /// `runTransaction` because the Firebase C++ SDK can call `abort()`
  /// inside transactions on Windows debug builds, crashing the app.
  /// For a POS system with one active cashier the collision risk is
  /// negligible.
  Future<String> generateInvoiceId() async {
    final counterRef = _firestore
        .collection(AppConstants.counterCollection)
        .doc('invoiceCounter');

    final snap = await counterRef.get();
    int currentCount = 0;
    if (snap.exists) {
      currentCount = (snap.data()?['count'] as int?) ?? 0;
    }
    final newCount = currentCount + 1;
    await counterRef.set({'count': newCount});
    return newCount.toString().padLeft(6, '0');
  }

  /// Saves an order and deducts stock in one atomic batch.
  Future<void> createOrder(Order order,
      List<Map<String, dynamic>> stockItems) async {
    final batch = _firestore.batch();

    // Save order
    final orderRef = _firestore
        .collection(AppConstants.ordersCollection)
        .doc(order.id);
    batch.set(orderRef, order.toFirestore());

    // Deduct stock
    for (final item in stockItems) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;
      final productRef = _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId);
      batch.update(productRef, {'stockQty': FieldValue.increment(-quantity)});
    }

    await batch.commit();
  }
}
