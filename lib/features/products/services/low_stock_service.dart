import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../orders/providers/orders_provider.dart';
import '../providers/products_provider.dart';
import '../../../models/product.dart';
import '../../../models/order.dart' as app_order;

class LowStockService {
  final List<Product> _products;
  final List<app_order.Order> _orders;

  LowStockService(this._products, this._orders);

  static const String _lastSentKey = 'last_low_stock_email_sent';

  /// Analyzes stock and sends an email via EmailJS if items are running low.
  /// If [isAutomatic] is true, it will only send if 24 hours have passed since the last email.
  Future<void> sendRestockEmail({bool isAutomatic = false}) async {
    if (isAutomatic) {
      final prefs = await SharedPreferences.getInstance();
      final lastSentStr = prefs.getString(_lastSentKey);
      if (lastSentStr != null) {
        final lastSent = DateTime.parse(lastSentStr);
        if (DateTime.now().difference(lastSent).inHours < 24) {
          return; // Don't spam, already sent within 24h
        }
      }
    }

    // 1. Find products with low stock (e.g., <= 5)
    final lowStockProducts = _products.where((p) => p.stockQty <= 5).toList();
    if (lowStockProducts.isEmpty) return;

    // 2. Filter orders from the last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentOrders = _orders.where((o) => o.createdAt.isAfter(thirtyDaysAgo)).toList();

    // 3. Calculate quantity sold in the last 30 days for low stock products
    final Map<String, int> salesData = {};
    for (final order in recentOrders) {
      for (final item in order.orderItems) {
        salesData[item.productId] = (salesData[item.productId] ?? 0) + item.quantity;
      }
    }

    // 4. Generate the email content
    final buffer = StringBuffer();
    for (final product in lowStockProducts) {
      final soldLast30Days = salesData[product.id] ?? 0;
      final recommendedRestock = soldLast30Days > 0 ? soldLast30Days : 10; // Default to 10 if no recent sales

      buffer.writeln('• ${product.name}');
      buffer.writeln('  Current Stock: ${product.stockQty}');
      buffer.writeln('  Sold (Last 30 Days): $soldLast30Days');
      buffer.writeln('  > Suggested Restock: $recommendedRestock units');
      buffer.writeln();
    }

    // 5. Send email via EmailJS REST API
    await _sendEmailJSPost(buffer.toString());

    // 6. Record timestamp to prevent spam
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSentKey, DateTime.now().toIso8601String());
  }

  Future<void> _sendEmailJSPost(String restockList) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'];
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'];
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'];

    if (serviceId == null || templateId == null || publicKey == null) {
      throw Exception('EmailJS credentials are not configured in .env');
    }

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'restock_list': restockList,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final lowStockServiceProvider = Provider<LowStockService>((ref) {
  final products = ref.watch(productsStreamProvider).valueOrNull ?? [];
  // For the service, we only need access to orders, not filtered
  final orders = ref.watch(ordersStreamProvider).valueOrNull ?? [];
  return LowStockService(products, orders);
});
