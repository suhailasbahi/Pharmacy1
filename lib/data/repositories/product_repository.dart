// lib/data/repositories/product_repository.dart
import '../datasources/remote/firebase_service.dart';
import '../datasources/models/product_model.dart';

class ProductRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<List<ProductModel>> getProducts(String companyId) async {
    final data = await _firebase.getCollection(
      'products',
      where: {'companyId': companyId, 'isActive': true},
    );
    return data.map((json) => ProductModel.fromMap(json['id'], json)).toList();
  }

  Future<ProductModel?> getProductById(String productId) async {
    final data = await _firebase.getDocument('products', productId);
    if (data == null) return null;
    return ProductModel.fromMap(productId, data);
  }

  Future<void> addProduct(ProductModel product) async {
    await _firebase.setDocument('products', product.id, product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firebase.updateDocument('products', product.id, product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _firebase.deleteDocument('products', productId);
  }

  Stream<List<ProductModel>> streamProducts(String companyId) {
    return _firebase.streamCollection(
      'products',
      where: {'companyId': companyId, 'isActive': true},
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(doc.id, data);
      }).toList();
    });
  }
}