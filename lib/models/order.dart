import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.dart';

class Order {
  final String id; // e.g. FACT-2026-001
  final String createdByUid;
  final String createdByName;
  final String customerName;
  final String customerDetails;
  final List<OrderItem> orderItems;
  final double totalAmount;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.createdByUid,
    required this.createdByName,
    required this.customerName,
    required this.customerDetails,
    required this.orderItems,
    required this.totalAmount,
    required this.createdAt,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['orderItems'] as List<dynamic>?)
            ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
    return Order(
      id: doc.id,
      createdByUid: data['createdByUid'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerDetails: data['customerDetails'] as String? ?? '',
      orderItems: itemsList,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'customerName': customerName,
      'customerDetails': customerDetails,
      'orderItems': orderItems.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
