import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/product.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProductsRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Stream of all products ordered by creation date.
  Stream<List<Product>> watchProducts() {
    return _firestore
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromFirestore).toList());
  }

  /// Uploads image bytes to Firebase Storage and returns the download URL.
  /// Uses putData (bytes) for cross-platform compatibility (Web/Desktop).
  Future<String> uploadProductImageBytes(
      Uint8List bytes, String productId, String fileName) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'png';
    final ref = _storage.ref().child('products/$productId.$ext');

    // Determine content type from extension
    String contentType = 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (ext == 'webp') {
      contentType = 'image/webp';
    } else if (ext == 'gif') {
      contentType = 'image/gif';
    }

    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  /// Creates a new product document in Firestore.
  Future<void> addProduct(Product product) async {
    final docRef =
        _firestore.collection(AppConstants.productsCollection).doc();
    final newProduct = product.copyWith(id: docRef.id);
    await docRef.set(newProduct.toFirestore());
  }

  /// Updates an existing product document.
  Future<void> updateProduct(Product product) async {
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .update(product.toFirestore());
  }

  /// Deletes a product document (and optionally its storage image).
  Future<void> deleteProduct(String productId) async {
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .delete();
  }

  /// Decrements stock for a list of items after an order is placed.
  Future<void> deductStock(
      List<Map<String, dynamic>> items, WriteBatch batch) async {
    for (final item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;
      final ref = _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId);
      batch.update(ref, {'stockQty': FieldValue.increment(-quantity)});
    }
  }
}
