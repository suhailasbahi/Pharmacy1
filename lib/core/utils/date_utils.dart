// lib/core/utils/date_utils.dart
import 'package:flutter/material.dart';
import '../../core/utils/date_filter_type.dart';
import '../../core/utils/date_range_model.dart';
import '../../core/utils/date_filter_helper.dart';

class DateUtilsHelper {
  /// تنسيق التاريخ
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    
    return format
        .replaceAll('dd', day)
        .replaceAll('MM', month)
        .replaceAll('yyyy', year)
        .replaceAll('yy', year.substring(2));
  }
  
  /// تنسيق الوقت
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// تنسيق التاريخ والوقت
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }
  
  /// الحصول على اسم اليوم
  static String getDayName(DateTime date) {
    const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[date.weekday % 7];
  }
  
  /// الحصول على اسم الشهر
  static String getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }
  
  /// بداية اليوم
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// نهاية اليوم
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  /// بداية الأسبوع (الأحد)
  static DateTime startOfWeek(DateTime date) {
    final diff = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - diff);
  }
  
  /// نهاية الأسبوع (السبت)
  static DateTime endOfWeek(DateTime date) {
    final diff = 6 - (date.weekday % 7);
    return DateTime(date.year, date.month, date.day + diff);
  }
  
  /// بداية الشهر
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// نهاية الشهر
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  /// بداية السنة
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }
  
  /// نهاية السنة
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }
  
  /// الحصول على نطاق تاريخ حسب النوع
  static DateRangeModel getDateRange(DateFilterType type, {DateTime? customStart, DateTime? customEnd}) {
    return DateFilterHelper.getRange(type, customStart: customStart, customEnd: customEnd);
  }
  
  /// هل التاريخ داخل النطاق؟
  static bool isWithinRange(DateTime date, DateRangeModel range) {
    return date.isAfter(range.start.subtract(const Duration(days: 1))) &&
        date.isBefore(range.end.add(const Duration(days: 1)));
  }
  
  /// الفرق بين تاريخين بالأيام
  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }
  
  /// الفرق بين تاريخين بالشهور
  static int monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }
  
  /// إضافة أشهر إلى تاريخ
  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }
  
  /// هل التاريخ اليوم؟
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  /// هل التاريخ في هذا الأسبوع؟
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = startOfWeek(now);
final weekEnd = endOfWeek(now);
return date.isAfter(weekStart) && date.isBefore(weekEnd);
  }
  
  /// هل التاريخ في هذا الشهر؟
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
  
  /// هل التاريخ في هذه السنة؟
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }
}