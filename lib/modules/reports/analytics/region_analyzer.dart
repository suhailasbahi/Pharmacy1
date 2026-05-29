// lib/modules/reports/analytics/region_analyzer.dart
import '../../../data/datasources/models/order_model.dart';
import '../../../core/services/sales_calculator.dart';
import '../models/report_models.dart';

class RegionAnalyzer {
  /// أفضل المناطق (حسب المبيعات)
  static Future<List<RegionReport>> getTopRegions(
    List<OrderModel> orders, {
    int limit = 10,
  }) async {
    final regionSales = SalesCalculator.calculateRegionSales(orders);
    final regions = regionSales.values.toList();
    regions.sort((a, b) => b.total.compareTo(a.total));
    
    return regions.take(limit).map((r) => RegionReport(
      regionName: r.regionName,
      sales: r.total,
      orderCount: r.orderCount,
      customerCount: r.customerCount,
      averageOrderValue: r.averageOrder,
    )).toList();
  }
  
  /// عدد المناطق التي تم البيع فيها
  static Future<int> getActiveRegionsCount(List<OrderModel> orders) async {
    final regionSales = SalesCalculator.calculateRegionSales(orders);
    return regionSales.length;
  }
  
  /// نصيب المنطقة من إجمالي المبيعات
  static Future<double> getRegionShare(
    List<OrderModel> orders,
    String regionName,
  ) async {
    final regionSales = SalesCalculator.calculateRegionSales(orders);
    final totalSales = regionSales.values.fold(0.0, (sum, r) => sum + r.total);
    final regionTotal = regionSales[regionName]?.total ?? 0;
    
    return totalSales > 0 ? (regionTotal / totalSales) * 100 : 0;
  }
  
  /// أفضل منتج في منطقة معينة
  static Future<({String productName, int quantity})?> getTopProductInRegion(
    List<OrderModel> orders,
    String regionName,
  ) async {
    final regionOrders = orders.where((o) => o.pharmacyCity == regionName).toList();
    final productSales = SalesCalculator.calculateProductSales(regionOrders);
    
    if (productSales.isEmpty) return null;
    
    final topProduct = productSales.values.reduce((a, b) => a.quantity > b.quantity ? a : b);
    return (productName: topProduct.productName, quantity: topProduct.quantity);
  }
  
  /// خريطة المبيعات حسب المنطقة (للرسم البياني)
  static Future<Map<String, double>> getRegionSalesMap(List<OrderModel> orders) async {
    final regionSales = SalesCalculator.calculateRegionSales(orders);
    final Map<String, double> result = {};
    
    for (var entry in regionSales.entries) {
      result[entry.key] = entry.value.total;
    }
    
    return result;
  }
}