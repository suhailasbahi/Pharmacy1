// lib/modules/reports/analytics/trend_analyzer.dart
import '../../../data/datasources/models/order_model.dart';
import '../../../core/services/sales_calculator.dart';
import '../../../core/services/statistics_calculator.dart';
import '../models/report_models.dart';

class TrendAnalyzer {
  /// تحليل اتجاه المبيعات
  static Future<TrendAnalysis> analyzeSalesTrend(List<OrderModel> orders) async {
    final monthlySales = SalesCalculator.calculateMonthlySales(orders);
    final values = monthlySales.values.toList();
    
    if (values.length < 2) {
      return TrendAnalysis(
        trend: 'مستقر',
        growthRate: 0,
        isIncreasing: false,
        isDecreasing: false,
      );
    }
    
    final current = values.last;
    final previous = values[values.length - 2];
    final growthRate = previous > 0 ? ((current - previous) / previous) * 100 : (current > 0 ? 100 : 0);
    final trend = StatisticsCalculator.getTrend(values);
    
    return TrendAnalysis(
      trend: _getTrendText(trend),
      growthRate: growthRate,
      isIncreasing: growthRate > 0,
      isDecreasing: growthRate < 0,
    );
  }
  
  /// توقعات المبيعات (بسيطة - متوسط آخر 3 أشهر)
  static Future<double> forecastSales(List<OrderModel> orders) async {
    final monthlySales = SalesCalculator.calculateMonthlySales(orders);
    final values = monthlySales.values.toList();
    
    if (values.isEmpty) return 0;
    if (values.length == 1) return values[0];
    
    // استخدام متوسط آخر 3 أشهر
    final lastThree = values.reversed.take(3).toList();
    return lastThree.reduce((a, b) => a + b) / lastThree.length;
  }
  
  /// تحليل مسار التحويل (Funnel)
  static Future<FunnelAnalysis> analyzeFunnel(List<OrderModel> orders) async {
    int pending = 0;
    int accepted = 0;
    int shipped = 0;
    int delivered = 0;
    int rejected = 0;
    
    for (var order in orders) {
      switch (order.status) {
        case 'pending': pending++; break;
        case 'accepted': accepted++; break;
        case 'shipped': shipped++; break;
        case 'delivered': delivered++; break;
        case 'rejected': rejected++; break;
      }
    }
    
    final total = orders.length;
    final conversionRate = total > 0 ? (delivered / total) * 100 : 0;
    final rejectionRate = total > 0 ? (rejected / total) * 100 : 0;
    
    return FunnelAnalysis(
      pending: pending,
      accepted: accepted,
      shipped: shipped,
      delivered: delivered,
      rejected: rejected,
      conversionRate: conversionRate,
      rejectionRate: rejectionRate,
    );
  }
  
  /// تحليل موسمي (مقارنة مع نفس الفترة من العام الماضي)
  static Future<SeasonalAnalysis> analyzeSeasonal(
    List<OrderModel> orders,
    int month,
  ) async {
    final thisYear = DateTime.now().year;
    final lastYear = thisYear - 1;
    
    double thisYearSales = 0;
    double lastYearSales = 0;
    
    for (var order in SalesCalculator.getCompletedOrders(orders)) {
      if (order.date.year == thisYear && order.date.month == month) {
        thisYearSales += order.totalPrice;
      } else if (order.date.year == lastYear && order.date.month == month) {
        lastYearSales += order.totalPrice;
      }
    }
    
    final growthRate = lastYearSales > 0 
        ? ((thisYearSales - lastYearSales) / lastYearSales) * 100 
        : (thisYearSales > 0 ? 100 : 0);
    
    return SeasonalAnalysis(
      currentYearSales: thisYearSales,
      previousYearSales: lastYearSales,
      growthRate: growthRate,
      isGrowing: growthRate > 0,
    );
  }
  
  /// أفضل وقت للبيع (أكثر شهر مبيعاً)
  static Future<BestPeriod> getBestSellingPeriod(List<OrderModel> orders) async {
    final monthlySales = SalesCalculator.calculateMonthlySales(orders);
    
    if (monthlySales.isEmpty) {
      return BestPeriod(month: 1, sales: 0);
    }
    
    var bestMonth = 1;
    var bestSales = 0.0;
    
    for (var entry in monthlySales.entries) {
      if (entry.value > bestSales) {
        bestSales = entry.value;
        bestMonth = int.parse(entry.key.split('-')[1]);
      }
    }
    
    return BestPeriod(month: bestMonth, sales: bestSales);
  }
  
  static String _getTrendText(String trend) {
    switch (trend) {
      case 'متزايد': return '📈 متزايد';
      case 'متناقص': return '📉 متناقص';
      default: return '➡️ مستقر';
    }
  }
}

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

class BestPeriod {
  final int month;
  final double sales;
  
  BestPeriod({
    required this.month,
    required this.sales,
  });
  
  String get monthName {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 
                    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return months[month - 1];
  }
}