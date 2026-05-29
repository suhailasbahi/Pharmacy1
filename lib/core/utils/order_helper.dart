// lib/core/utils/order_helper.dart
import 'package:flutter/material.dart';
import '../../data/datasources/models/order_model.dart';
import '../../core/constants/app_constants.dart';

class OrderHelper {
  /// الحصول على نص حالة الطلب
  static String getStatusText(String status) {
    return AppConstants.orderStatusLabels[status] ?? status;
  }
  
  /// الحصول على لون حالة الطلب
  static Color getStatusColor(String status) {
    return AppConstants.orderStatusColors[status] ?? Colors.grey;
  }
  
  /// تنسيق التاريخ
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// حساب إجمالي عدد المنتجات في الطلب
  static int getTotalItems(OrderModel order) {
    return order.items.length;
  }
  
  /// حساب إجمالي الكمية (بالوحدات)
  static int getTotalQuantity(OrderModel order) {
    return order.items.fold(0, (sum, item) => sum + item.quantity);
  }
  
  /// حساب إجمالي القطع (باكيتات)
  static int getTotalPieces(OrderModel order) {
    return order.items.fold(0, (sum, item) => sum + item.quantityInPieces);
  }
  
  /// التحقق من إمكانية تعديل الطلب
  static bool isEditable(OrderModel order) {
    return order.status == 'pending';
  }
  
  /// التحقق من إمكانية إلغاء الطلب
  static bool isCancellable(OrderModel order) {
    return order.status == 'pending' || order.status == 'accepted';
  }
}