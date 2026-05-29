// lib/modules/reports/models/report_models.dart
import '../../../data/datasources/models/order_model.dart';

// ==================== نماذج التقارير الأساسية ====================

/// فترة التقرير
class ReportPeriod {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCustom;

  ReportPeriod({
    this.startDate,
    this.endDate,
    this.isCustom = false,
  });

  factory ReportPeriod.today() {
    final now = DateTime.now();
    return ReportPeriod(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: now,
    );
  }

  factory ReportPeriod.week() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return ReportPeriod(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: now,
    );
  }

  factory ReportPeriod.month() {
    final now = DateTime.now();
    return ReportPeriod(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );
  }

  factory ReportPeriod.year() {
    final now = DateTime.now();
    return ReportPeriod(
      startDate: DateTime(now.year, 1, 1),
      endDate: now,
    );
  }

  bool contains(DateTime date) {
    if (startDate == null || endDate == null) return true;
    return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(endDate!.add(const Duration(days: 1)));
  }

  @override
  String toString() {
    if (startDate == null || endDate == null) return 'كل الفترات';
    return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

/// ملخص المبيعات
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

  factory SalesSummary.empty() => SalesSummary(
    totalSales: 0,
    cashSales: 0,
    creditSales: 0,
    totalOrders: 0,
    cashOrders: 0,
    creditOrders: 0,
    averageOrderValue: 0,
  );
}

/// إحصاءات حالة الطلبات
class OrderStatusStats {
  final int pending;
  final int accepted;
  final int shipped;
  final int delivered;
  final int rejected;

  OrderStatusStats({
    this.pending = 0,
    this.accepted = 0,
    this.shipped = 0,
    this.delivered = 0,
    this.rejected = 0,
  });

  int get total => pending + accepted + shipped + delivered + rejected;
  int get completed => accepted + shipped + delivered;

  double get conversionRate => total > 0 ? (completed / total) * 100 : 0;
  double get rejectionRate => total > 0 ? (rejected / total) * 100 : 0;
}

/// تقرير المنتج
class ProductReport {
  final String productId;
  final String productName;
  final String scientificName;
  final int quantitySold;
  final double revenue;
  final int orderCount;

  ProductReport({
    required this.productId,
    required this.productName,
    required this.scientificName,
    this.quantitySold = 0,
    this.revenue = 0,
    this.orderCount = 0,
  });

  double get averagePrice => quantitySold > 0 ? revenue / quantitySold : 0;
}

/// تقرير العميل (للشركات)
class CustomerReport {
  final String customerId;
  final String customerName;
  final String customerCity;
  final double totalPurchases;
  final int orderCount;
  final double cashPurchases;
  final double creditPurchases;

  CustomerReport({
    required this.customerId,
    required this.customerName,
    required this.customerCity,
    this.totalPurchases = 0,
    this.orderCount = 0,
    this.cashPurchases = 0,
    this.creditPurchases = 0,
  });

  double get averageOrderValue => orderCount > 0 ? totalPurchases / orderCount : 0;
  double get cashPercentage => totalPurchases > 0 ? (cashPurchases / totalPurchases) * 100 : 0;
  double get creditPercentage => totalPurchases > 0 ? (creditPurchases / totalPurchases) * 100 : 0;
}

/// تقرير المورد (للصيدليات)
class SupplierReport {
  final String supplierId;
  final String supplierName;
  final double totalPurchases;
  final int orderCount;
  final double cashPurchases;
  final double creditPurchases;

  SupplierReport({
    required this.supplierId,
    required this.supplierName,
    this.totalPurchases = 0,
    this.orderCount = 0,
    this.cashPurchases = 0,
    this.creditPurchases = 0,
  });

  double get averageOrderValue => orderCount > 0 ? totalPurchases / orderCount : 0;
  double get cashPercentage => totalPurchases > 0 ? (cashPurchases / totalPurchases) * 100 : 0;
  double get creditPercentage => totalPurchases > 0 ? (creditPurchases / totalPurchases) * 100 : 0;
}

/// تقرير المنطقة
class RegionReport {
  final String regionName;
  final double sales;
  final int orderCount;
  final int customerCount;

  RegionReport({
    required this.regionName,
    this.sales = 0,
    this.orderCount = 0,
    this.customerCount = 0,
  });

  double get averageOrderValue => orderCount > 0 ? sales / orderCount : 0;
  double get percentageOfTotal {
    // سيتم حسابه خارجياً
    return 0;
  }
}

/// بيانات الرسم البياني
class ChartData {
  final String label;
  final double value;
  final DateTime? date;

  ChartData({
    required this.label,
    required this.value,
    this.date,
  });
}

/// نقطة بيانات للرسم البياني الدائري
class PieChartDataPoint {
  final String label;
  final double value;

  PieChartDataPoint({
    required this.label,
    required this.value,
  });
}

// ==================== نماذج التحليلات المتقدمة ====================

/// تحليل الاتجاه
class TrendAnalysis {
  final String trend;
  final double growthRate;
  final bool isIncreasing;
  final bool isDecreasing;

  TrendAnalysis({
    required this.trend,
    required this.growthRate,
    required this.isIncreasing,
    required this.isDecreasing,
  });
}

/// تحليل مسار التحويل (Funnel)
class FunnelAnalysis {
  final int pending;
  final int accepted;
  final int shipped;
  final int delivered;
  final int rejected;
  final double conversionRate;
  final double rejectionRate;

  FunnelAnalysis({
    required this.pending,
    required this.accepted,
    required this.shipped,
    required this.delivered,
    required this.rejected,
    required this.conversionRate,
    required this.rejectionRate,
  });

  int get total => pending + accepted + shipped + delivered + rejected;
}

/// تحليل موسمي
class SeasonalAnalysis {
  final double currentYearSales;
  final double previousYearSales;
  final double growthRate;
  final bool isGrowing;

  SeasonalAnalysis({
    required this.currentYearSales,
    required this.previousYearSales,
    required this.growthRate,
    required this.isGrowing,
  });
}

/// أفضل فترة
class BestPeriod {
  final int month;
  final double sales;

  BestPeriod({
    required this.month,
    required this.sales,
  });

  String get monthName {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }
}