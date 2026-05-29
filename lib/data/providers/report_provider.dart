// lib/data/providers/report_provider.dart
import 'package:flutter/material.dart';
import '../../modules/reports/data/report_repository.dart';
import '../../modules/reports/analytics/product_analyzer.dart';
import '../../modules/reports/models/report_models.dart';
import 'package:app/core/exports.dart';
// lib/data/providers/report_provider.dart
// أضف هذا الـ import في بداية الملف
import 'package:app/data/datasources/models/order_model.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository = ReportRepository();
  
  List<ProductReport> _allProducts = [];
  String _searchQuery = '';
  String _sortBy = 'quantity'; // quantity, revenue, orders
  bool _isLoading = false;
  
  // ==================== Getters ====================
  
  List<ProductReport> get filteredProducts {
    var products = List<ProductReport>.from(_allProducts);
    
    // فلترة
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) =>
        p.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.scientificName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // ترتيب
    switch (_sortBy) {
      case 'revenue':
        products.sort((a, b) => b.revenue.compareTo(a.revenue));
        break;
      case 'orders':
        products.sort((a, b) => b.orderCount.compareTo(a.orderCount));
        break;
      default:
        products.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    }
    
    return products;
  }
  
  int get totalProducts => _allProducts.length;
  int get filteredCount => filteredProducts.length;
  bool get isLoading => _isLoading;
  String get currentSortBy => _sortBy;
  String get currentSearchQuery => _searchQuery;
  
  // ==================== Actions ====================
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }
  
  void clearFilters() {
    _searchQuery = '';
    _sortBy = 'quantity';
    notifyListeners();
  }
  
  Future<void> loadTopProducts(List<OrderModel> orders) async {
    _isLoading = true;
    notifyListeners();
    
    _allProducts = await ProductAnalyzer.getTopProductsByQuantity(orders);
    
    _isLoading = false;
    notifyListeners();
  }
  
  // إحصائيات سريعة
  int get totalQuantitySold => _allProducts.fold(0, (sum, p) => sum + p.quantitySold);
  double get totalRevenue => _allProducts.fold(0.0, (sum, p) => sum + p.revenue);
  
  // أفضل 5 منتجات (للمخطط)
  List<ChartData> get top5ProductsChartData {
    return filteredProducts.take(5).map((p) => ChartData(
      label: p.productName.length > 15 ? '${p.productName.substring(0, 15)}...' : p.productName,
      value: p.quantitySold.toDouble(),
    )).toList();
  }
  
  // بيانات الجدول
  List<List<dynamic>> get tableData {
    return filteredProducts.map((p) => [
      p.productName,
      p.quantitySold,
      p.revenue,
      p.orderCount,
      p.averagePrice,
    ]).toList();
  }
}