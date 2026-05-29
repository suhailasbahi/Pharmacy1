// lib/modules/reports/analytics/product_analyzer.dart
import '../../../data/datasources/models/order_model.dart';
import '../../../core/services/sales_calculator.dart';
import '../models/report_models.dart';

class ProductAnalyzer {
  /// أفضل المنتجات مبيعاً (حسب الكمية)
  static Future<List<ProductReport>> getTopProductsByQuantity(
    List<OrderModel> orders, {
    int limit = 10,
  }) async {
    final productSales = SalesCalculator.calculateProductSales(orders);
    final products = productSales.values.toList();
    products.sort((a, b) => b.quantity.compareTo(a.quantity));
    return products.take(limit).map((p) => ProductReport(
      productId: p.productId,
      productName: p.productName,
      scientificName: p.scientificName,
      quantitySold: p.quantity,
      revenue: p.revenue,
      orderCount: p.orderCount,
      averagePrice: p.averagePrice,
    )).toList();
  }
  
  /// أفضل المنتجات من حيث الإيرادات
  static Future<List<ProductReport>> getTopProductsByRevenue(
    List<OrderModel> orders, {
    int limit = 10,
  }) async {
    final productSales = SalesCalculator.calculateProductSales(orders);
    final products = productSales.values.toList();
    products.sort((a, b) => b.revenue.compareTo(a.revenue));
    return products.take(limit).map((p) => ProductReport(
      productId: p.productId,
      productName: p.productName,
      scientificName: p.scientificName,
      quantitySold: p.quantity,
      revenue: p.revenue,
      orderCount: p.orderCount,
      averagePrice: p.averagePrice,
    )).toList();
  }
  
  /// المنتجات الأقل مبيعاً (راكدة)
  static Future<List<ProductReport>> getBottomProducts(
    List<OrderModel> orders, {
    int limit = 10,
  }) async {
    final productSales = SalesCalculator.calculateProductSales(orders);
    final products = productSales.values.toList();
    products.sort((a, b) => a.quantity.compareTo(b.quantity));
    return products.take(limit).map((p) => ProductReport(
      productId: p.productId,
      productName: p.productName,
      scientificName: p.scientificName,
      quantitySold: p.quantity,
      revenue: p.revenue,
      orderCount: p.orderCount,
      averagePrice: p.averagePrice,
    )).toList();
  }
  
  /// إجمالي عدد المنتجات المباعة
  static Future<int> getTotalProductsSold(List<OrderModel> orders) async {
    final productSales = SalesCalculator.calculateProductSales(orders);
    return productSales.values.fold(0, (sum, p) => sum + p.quantity);
  }
  
  /// إجمالي عدد المنتجات الفريدة المباعة
  static Future<int> getUniqueProductsSold(List<OrderModel> orders) async {
    final productSales = SalesCalculator.calculateProductSales(orders);
    return productSales.length;
  }
  
  /// متوسط سعر البيع للمنتج
  static Future<double> getAverageSellingPrice(List<OrderModel> orders) async {
    final productSales = SalesCalculator.calculateProductSales(orders);
    if (productSales.isEmpty) return 0;
    
    double totalRevenue = 0;
    int totalQuantity = 0;
    
    for (var p in productSales.values) {
      totalRevenue += p.revenue;
      totalQuantity += p.quantity;
    }
    
    return totalQuantity > 0 ? totalRevenue / totalQuantity : 0;
  }
}