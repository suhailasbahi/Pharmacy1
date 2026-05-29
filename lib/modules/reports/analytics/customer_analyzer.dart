// lib/modules/reports/analytics/customer_analyzer.dart
import '../../../data/datasources/models/order_model.dart';
import '../../../core/services/sales_calculator.dart';
import '../models/report_models.dart';

class CustomerAnalyzer {
  /// أفضل العملاء (حسب إجمالي المشتريات)
  static Future<List<CustomerReport>> getTopCustomers(
    List<OrderModel> orders, {
    int limit = 10,
  }) async {
    final customerSales = SalesCalculator.calculateCustomerSales(orders);
    final customers = customerSales.values.toList();
    customers.sort((a, b) => b.total.compareTo(a.total));
    
    return customers.take(limit).map((c) => CustomerReport(
      customerId: c.customerId,
      customerName: c.customerName,
      customerCity: c.customerCity,
      totalPurchases: c.total,
      orderCount: c.orderCount,
      cashPurchases: c.cash,
      creditPurchases: c.credit,
      averageOrderValue: c.averageOrder,
    )).toList();
  }
  
  /// عدد العملاء النشطين
  static Future<int> getActiveCustomersCount(List<OrderModel> orders) async {
    final customerSales = SalesCalculator.calculateCustomerSales(orders);
    return customerSales.length;
  }
  
  /// العملاء الذين لديهم رصيد (مشتريات آجلة)
  static Future<List<CustomerReport>> getCustomersWithCredit(
    List<OrderModel> orders,
  ) async {
    final customerSales = SalesCalculator.calculateCustomerSales(orders);
    final customers = customerSales.values
        .where((c) => c.credit > 0)
        .map((c) => CustomerReport(
          customerId: c.customerId,
          customerName: c.customerName,
          customerCity: c.customerCity,
          totalPurchases: c.total,
          orderCount: c.orderCount,
          cashPurchases: c.cash,
          creditPurchases: c.credit,
          averageOrderValue: c.averageOrder,
        ))
        .toList();
    
    customers.sort((a, b) => b.creditPurchases.compareTo(a.creditPurchases));
    return customers;
  }
  
  /// العملاء الجدد (أول طلب لهم خلال الفترة)
  static Future<List<CustomerReport>> getNewCustomers(
    List<OrderModel> orders,
  ) async {
    final customerFirstOrder = <String, DateTime>{};
    
    for (var order in orders) {
      if (!customerFirstOrder.containsKey(order.pharmacyId)) {
        customerFirstOrder[order.pharmacyId] = order.date;
      } else if (order.date.isBefore(customerFirstOrder[order.pharmacyId]!)) {
        customerFirstOrder[order.pharmacyId] = order.date;
      }
    }
    
    // نأخذ أصحاب أول طلب خلال الـ 30 يوم الماضية
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final newCustomerIds = customerFirstOrder.entries
        .where((e) => e.value.isAfter(thirtyDaysAgo))
        .map((e) => e.key)
        .toSet();
    
    final customerSales = SalesCalculator.calculateCustomerSales(orders);
    return customerSales.values
        .where((c) => newCustomerIds.contains(c.customerId))
        .map((c) => CustomerReport(
          customerId: c.customerId,
          customerName: c.customerName,
          customerCity: c.customerCity,
          totalPurchases: c.total,
          orderCount: c.orderCount,
          cashPurchases: c.cash,
          creditPurchases: c.credit,
          averageOrderValue: c.averageOrder,
        ))
        .toList();
  }
  
  /// إجمالي مشتريات جميع العملاء
  static Future<double> getTotalCustomerPurchases(List<OrderModel> orders) async {
    final customerSales = SalesCalculator.calculateCustomerSales(orders);
    return customerSales.values.fold(0.0, (sum, c) => sum + c.total);
  }
}