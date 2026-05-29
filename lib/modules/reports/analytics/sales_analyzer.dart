// lib/modules/reports/analytics/sales_analyzer.dart
import '../../../data/datasources/models/order_model.dart';
import '../../../core/services/sales_calculator.dart';
import '../models/report_models.dart';

class SalesAnalyzer {
  /// حساب ملخص المبيعات
  static Future<SalesSummary> getSalesSummary(List<OrderModel> orders) async {
    return SalesCalculator.calculateSummary(orders);
  }
  
  /// حساب إحصائيات الطلبات
  static Future<OrderStatusStats> getOrderStats(List<OrderModel> orders) async {
    return SalesCalculator.calculateOrderStats(orders);
  }
  
  /// المبيعات الشهرية
  static Future<Map<String, double>> getMonthlySales(List<OrderModel> orders) async {
    return SalesCalculator.calculateMonthlySales(orders);
  }
  
  /// المبيعات اليومية
  static Future<Map<String, double>> getDailySales(List<OrderModel> orders) async {
    return SalesCalculator.calculateDailySales(orders);
  }
  
  /// اتجاه المبيعات (نسبة النمو)
  static Future<double> getSalesTrend(List<OrderModel> orders) async {
    final monthlySales = await getMonthlySales(orders);
    final values = monthlySales.values.toList();
    if (values.length < 2) return 0;
    
    final current = values.last;
    final previous = values[values.length - 2];
    if (previous == 0) return current > 0 ? 100 : 0;
    
    return ((current - previous) / previous) * 100;
  }
  
  /// متوسط قيمة الطلب
  static Future<double> getAverageOrderValue(List<OrderModel> orders) async {
    final summary = await getSalesSummary(orders);
    return summary.averageOrderValue;
  }
}