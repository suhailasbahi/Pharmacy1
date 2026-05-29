// lib/modules/reports/analytics/supplier_analyzer.dart
import '../../../data/datasources/models/order_model.dart';
import '../../../core/services/sales_calculator.dart';
import '../models/report_models.dart';

class SupplierAnalyzer {
  /// أفضل الموردين (حسب إجمالي المشتريات)
  static Future<List<SupplierReport>> getTopSuppliers(
    List<OrderModel> orders, {
    int limit = 10,
  }) async {
    final supplierStats = _calculateSupplierStats(orders);
    final suppliers = supplierStats.values.toList();
    suppliers.sort((a, b) => b.totalPurchases.compareTo(a.totalPurchases));
    
    return suppliers.take(limit).map((s) => SupplierReport(
      supplierId: s.supplierId,
      supplierName: s.supplierName,
      totalPurchases: s.totalPurchases,
      orderCount: s.orderCount,
      cashPurchases: s.cashPurchases,
      creditPurchases: s.creditPurchases,
      averageOrderValue: s.averageOrderValue,
    )).toList();
  }
  
  /// عدد الموردين
  static Future<int> getSuppliersCount(List<OrderModel> orders) async {
    final supplierStats = _calculateSupplierStats(orders);
    return supplierStats.length;
  }
  
  /// الموردين الذين لديهم رصيد (مشتريات آجلة)
  static Future<List<SupplierReport>> getSuppliersWithCredit(
    List<OrderModel> orders,
  ) async {
    final supplierStats = _calculateSupplierStats(orders);
    final suppliers = supplierStats.values
        .where((s) => s.creditPurchases > 0)
        .map((s) => SupplierReport(
          supplierId: s.supplierId,
          supplierName: s.supplierName,
          totalPurchases: s.totalPurchases,
          orderCount: s.orderCount,
          cashPurchases: s.cashPurchases,
          creditPurchases: s.creditPurchases,
          averageOrderValue: s.averageOrderValue,
        ))
        .toList();
    
    suppliers.sort((a, b) => b.creditPurchases.compareTo(a.creditPurchases));
    return suppliers;
  }
  
  /// مشتريات الموردين حسب الشهر
  static Future<Map<String, Map<String, double>>> getSupplierMonthlyPurchases(
    List<OrderModel> orders,
  ) async {
    final result = <String, Map<String, double>>{};
    
    for (var order in SalesCalculator.getCompletedOrders(orders)) {
      final supplierName = order.companyName;
      final monthKey = '${order.date.year}-${order.date.month.toString().padLeft(2, '0')}';
      
      if (!result.containsKey(supplierName)) {
        result[supplierName] = {};
      }
      
      result[supplierName]![monthKey] = 
          (result[supplierName]![monthKey] ?? 0) + order.totalPrice;
    }
    
    return result;
  }
  
  static Map<String, _SupplierStats> _calculateSupplierStats(List<OrderModel> orders) {
    final result = <String, _SupplierStats>{};
    final completedOrders = SalesCalculator.getCompletedOrders(orders);
    
    for (var order in completedOrders) {
      if (!result.containsKey(order.companyId)) {
        result[order.companyId] = _SupplierStats(
          supplierId: order.companyId,
          supplierName: order.companyName,
        );
      }
      
      final stats = result[order.companyId]!;
      stats.totalPurchases += order.totalPrice;
      stats.orderCount += 1;
      
      if (order.paymentType == 'cash') {
        stats.cashPurchases += order.totalPrice;
      } else {
        stats.creditPurchases += order.totalPrice;
      }
    }
    
    return result;
  }
}

class _SupplierStats {
  final String supplierId;
  final String supplierName;
  double totalPurchases = 0;
  int orderCount = 0;
  double cashPurchases = 0;
  double creditPurchases = 0;
  
  _SupplierStats({
    required this.supplierId,
    required this.supplierName,
  });
  
  double get averageOrderValue => orderCount > 0 ? totalPurchases / orderCount : 0;
}