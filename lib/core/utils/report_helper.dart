// lib/core/utils/report_helper.dart
import 'package:flutter/material.dart';
import '../../data/datasources/models/order_model.dart';
import '../../core/extensions/num_extensions.dart';

class ReportHelper {
  /// حساب المبيعات الشهرية
  static Map<String, double> calculateMonthlySales(List<OrderModel> orders) {
    final Map<String, double> result = {};
    final completedOrders = _getCompletedOrders(orders);
    
    for (var order in completedOrders) {
      final key = '${order.date.year}-${order.date.month.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + order.totalPrice;
    }
    
    return result;
  }
  
  /// حساب المبيعات اليومية (آخر 30 يوم)
  static Map<String, double> calculateDailySales(List<OrderModel> orders) {
    final Map<String, double> result = {};
    final completedOrders = _getCompletedOrders(orders);
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    for (var order in completedOrders) {
      if (order.date.isAfter(thirtyDaysAgo)) {
        final key = '${order.date.day}/${order.date.month}';
        result[key] = (result[key] ?? 0) + order.totalPrice;
      }
    }
    
    return result;
  }
  
  /// حساب توزيع الدفع (نقدي/آجل)
  static Map<String, double> calculatePaymentDistribution(List<OrderModel> orders) {
    final completedOrders = _getCompletedOrders(orders);
    double cashTotal = 0;
    double creditTotal = 0;
    
    for (var order in completedOrders) {
      if (order.paymentType == 'cash') {
        cashTotal += order.totalPrice;
      } else {
        creditTotal += order.totalPrice;
      }
    }
    
    return {
      'cash': cashTotal,
      'credit': creditTotal,
    };
  }
  
  /// الحصول على آخر الطلبات (للعرض في التقرير)
  static List<OrderModel> getRecentOrders(List<OrderModel> orders, {int limit = 20}) {
    final completedOrders = _getCompletedOrders(orders);
    final sorted = List<OrderModel>.from(completedOrders)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
  
  /// تنسيق بيانات الجدول لآخر الطلبات
  static List<List<dynamic>> getRecentOrdersTableData(List<OrderModel> orders) {
    final recentOrders = getRecentOrders(orders);
    return recentOrders.map((order) => [
      order.date,
      order.pharmacyName,
      order.items.length,
      order.totalPrice,
      order.paymentType == 'cash' ? 'نقدي' : 'آجل',
      order.statusText,
    ]).toList();
  }
  
  /// الحصول على الطلبات المكتملة فقط
  static List<OrderModel> _getCompletedOrders(List<OrderModel> orders) {
    const completedStatuses = ['accepted', 'shipped', 'delivered'];
    return orders.where((o) => completedStatuses.contains(o.status)).toList();
  }
  
  /// تنسيق بيانات الرسم البياني
  static List<ChartDataPoint> toChartData(Map<String, double> data) {
    return data.entries
        .map((e) => ChartDataPoint(label: e.key, value: e.value))
        .toList();
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  
  ChartDataPoint({required this.label, required this.value});
}