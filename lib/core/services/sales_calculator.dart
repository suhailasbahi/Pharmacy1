// lib/core/services/sales_calculator.dart
import '../../data/datasources/models/order_model.dart';

class SalesCalculator {
  /// الحصول على الطلبات المكتملة فقط
  static List<OrderModel> getCompletedOrders(List<OrderModel> orders) {
    const completedStatuses = ['accepted', 'shipped', 'delivered'];
    return orders.where((o) => completedStatuses.contains(o.status)).toList();
  }
  
  /// حساب ملخص المبيعات
  static SalesSummary calculateSummary(List<OrderModel> orders) {
    final completedOrders = getCompletedOrders(orders);
    
    double totalSales = 0;
    double cashSales = 0;
    double creditSales = 0;
    int cashOrders = 0;
    int creditOrders = 0;
    
    for (var order in completedOrders) {
      totalSales += order.totalPrice;
      if (order.paymentType == 'cash') {
        cashSales += order.totalPrice;
        cashOrders++;
      } else {
        creditSales += order.totalPrice;
        creditOrders++;
      }
    }
    
    return SalesSummary(
      totalSales: totalSales,
      cashSales: cashSales,
      creditSales: creditSales,
      totalOrders: completedOrders.length,
      cashOrders: cashOrders,
      creditOrders: creditOrders,
      averageOrderValue: completedOrders.isEmpty ? 0 : totalSales / completedOrders.length,
    );
  }
  
  /// حساب مبيعات حسب العميل
  static Map<String, CustomerSalesData> calculateCustomerSales(List<OrderModel> orders) {
    final Map<String, CustomerSalesData> result = {};
    
    for (var order in getCompletedOrders(orders)) {
      if (!result.containsKey(order.pharmacyId)) {
        result[order.pharmacyId] = CustomerSalesData(
          customerId: order.pharmacyId,
          customerName: order.pharmacyName,
          customerCity: order.pharmacyCity,
        );
      }
      
      final data = result[order.pharmacyId]!;
      data.total += order.totalPrice;
      data.orderCount++;
      
      if (order.paymentType == 'cash') {
        data.cash += order.totalPrice;
      } else {
        data.credit += order.totalPrice;
      }
    }
    
    return result;
  }
  
  /// حساب مبيعات حسب المنطقة
  static Map<String, RegionSalesData> calculateRegionSales(List<OrderModel> orders) {
    final Map<String, RegionSalesData> result = {};
    
    for (var order in getCompletedOrders(orders)) {
      final region = order.pharmacyCity.isEmpty ? 'غير محدد' : order.pharmacyCity;
      
      if (!result.containsKey(region)) {
        result[region] = RegionSalesData(regionName: region);
      }
      
      final data = result[region]!;
      data.total += order.totalPrice;
      data.orderCount++;
      data.uniqueCustomers.add(order.pharmacyId);
    }
    
    return result;
  }
  
  /// حساب مبيعات حسب المنتج
  static Map<String, ProductSalesData> calculateProductSales(List<OrderModel> orders) {
    final Map<String, ProductSalesData> result = {};
    
    for (var order in getCompletedOrders(orders)) {
      for (var item in order.items) {
        if (!result.containsKey(item.productId)) {
          result[item.productId] = ProductSalesData(
            productId: item.productId,
            productName: item.productName,
            scientificName: item.scientificName,
          );
        }
        
        final data = result[item.productId]!;
        data.quantity += item.quantity;
        data.revenue += item.totalPrice;
        data.orderCount++;
      }
    }
    
    return result;
  }
  
  /// المبيعات اليومية
  static Map<String, double> calculateDailySales(List<OrderModel> orders) {
    final Map<String, double> result = {};
    
    for (var order in getCompletedOrders(orders)) {
      final key = '${order.date.year}-${order.date.month}-${order.date.day}';
      result[key] = (result[key] ?? 0) + order.totalPrice;
    }
    
    return result;
  }
  
  /// المبيعات الشهرية
  static Map<String, double> calculateMonthlySales(List<OrderModel> orders) {
    final Map<String, double> result = {};
    
    for (var order in getCompletedOrders(orders)) {
      final key = '${order.date.year}-${order.date.month.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + order.totalPrice;
    }
    
    return result;
  }
  
  /// المبيعات السنوية
  static Map<int, double> calculateYearlySales(List<OrderModel> orders) {
    final Map<int, double> result = {};
    
    for (var order in getCompletedOrders(orders)) {
      result[order.date.year] = (result[order.date.year] ?? 0) + order.totalPrice;
    }
    
    return result;
  }
  
  /// أفضل العملاء (مرتبين)
  static List<CustomerSalesData> getTopCustomers(List<OrderModel> orders, {int limit = 10}) {
    final customerSales = calculateCustomerSales(orders);
    final customers = customerSales.values.toList();
    customers.sort((a, b) => b.total.compareTo(a.total));
    return customers.take(limit).toList();
  }
  
  /// أفضل المنتجات (مرتبين)
  static List<ProductSalesData> getTopProducts(List<OrderModel> orders, {int limit = 10}) {
    final productSales = calculateProductSales(orders);
    final products = productSales.values.toList();
    products.sort((a, b) => b.quantity.compareTo(a.quantity));
    return products.take(limit).toList();
  }
  
  /// أفضل المناطق (مرتبين)
  static List<RegionSalesData> getTopRegions(List<OrderModel> orders, {int limit = 10}) {
    final regionSales = calculateRegionSales(orders);
    final regions = regionSales.values.toList();
    regions.sort((a, b) => b.total.compareTo(a.total));
    return regions.take(limit).toList();
  }
}

// ==================== نماذج البيانات ====================

class SalesSummary {
  final double totalSales;
  final double cashSales;
  final double creditSales;
  final int totalOrders;
  final int cashOrders;
  final int creditOrders;
  final double averageOrderValue;
  
  SalesSummary({
    required this.totalSales,
    required this.cashSales,
    required this.creditSales,
    required this.totalOrders,
    required this.cashOrders,
    required this.creditOrders,
    required this.averageOrderValue,
  });
  
  double get cashPercentage => totalSales > 0 ? (cashSales / totalSales) * 100 : 0;
  double get creditPercentage => totalSales > 0 ? (creditSales / totalSales) * 100 : 0;
}

class CustomerSalesData {
  final String customerId;
  final String customerName;
  final String customerCity;
  double total = 0;
  int orderCount = 0;
  double cash = 0;
  double credit = 0;
  
  CustomerSalesData({
    required this.customerId,
    required this.customerName,
    required this.customerCity,
  });
  
  double get averageOrder => orderCount > 0 ? total / orderCount : 0;
  double get cashPercentage => total > 0 ? (cash / total) * 100 : 0;
  double get creditPercentage => total > 0 ? (credit / total) * 100 : 0;
}

class RegionSalesData {
  final String regionName;
  double total = 0;
  int orderCount = 0;
  final Set<String> uniqueCustomers = {};
  
  RegionSalesData({required this.regionName});
  
  int get customerCount => uniqueCustomers.length;
  double get averageOrder => orderCount > 0 ? total / orderCount : 0;
}

class ProductSalesData {
  final String productId;
  final String productName;
  final String scientificName;
  int quantity = 0;
  double revenue = 0;
  int orderCount = 0;
  
  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.scientificName,
  });
  
  double get averagePrice => quantity > 0 ? revenue / quantity : 0;
  double get averagePerOrder => orderCount > 0 ? revenue / orderCount : 0;
}