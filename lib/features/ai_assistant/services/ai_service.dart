import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../models/product.dart';
import '../../../models/order.dart' as app_order;

class AiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GenerativeModel _model;

  AiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
You are an AI Business Assistant for a Point of Sale & Inventory system named Dar Belamri.
Your goal is to help the business owner analyze their data, understand stock levels, and make business decisions.
You will be provided with JSON data representing the current state of the store's inventory and recent orders.
Answer concisely and naturally. Support Arabic, French, and English depending on the user's prompt.
Keep your answers brief and easy to read on a mobile/desktop screen. Do not output raw JSON to the user.
'''),
    );
  }

  Future<String> askQuestion(String prompt) async {
    try {
      // 1. Fetch current data context
      final productsSnapshot = await _firestore.collection('products').get();
      final products = productsSnapshot.docs
          .map((d) => Product.fromFirestore(d))
          .toList();

      // Fetch recent orders (last 30 days or so, let's just get last 100 for context)
      final ordersSnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      
      final orders = ordersSnapshot.docs
          .map((d) => app_order.Order.fromFirestore(d))
          .toList();

      // 2. Build JSON context
      final contextData = {
        'currentDate': DateTime.now().toIso8601String(),
        'inventory': products.map((p) => {
          'name': p.name,
          'price': p.price,
          'stockQty': p.stockQty,
        }).toList(),
        'recentOrders': orders.map((o) => {
          'id': o.id,
          'totalAmount': o.totalAmount,
          'date': o.createdAt.toIso8601String(),
          'items': o.orderItems.map((i) => {
            'productName': i.productName,
            'qty': i.quantity,
            'price': i.unitPrice,
          }).toList(),
        }).toList(),
      };

      final contextJson = jsonEncode(contextData);

      // 3. Prompt Gemini
      final finalPrompt = '''
User Question: $prompt

Here is the current business data in JSON:
$contextJson

Please answer the user's question based on this data.
''';

      final content = [Content.text(finalPrompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Sorry, I could not generate an answer.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}
