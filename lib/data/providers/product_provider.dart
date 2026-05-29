// lib/data/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../repositories/product_repository.dart';
import '../datasources/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  List<ProductModel> _products = [];
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts(String companyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _repository.getProducts(companyId);
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<ProductModel>> streamProducts(String companyId) {
    return _repository.streamProducts(companyId);
  }

  Future<void> addProduct(ProductModel product) async {
    await _repository.addProduct(product);
    await loadProducts(product.companyId);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repository.updateProduct(product);
    await loadProducts(product.companyId);
  }

  Future<void> deleteProduct(String productId, String companyId) async {
    await _repository.deleteProduct(productId);
    await loadProducts(companyId);
  }
}