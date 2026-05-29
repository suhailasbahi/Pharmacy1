// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // الثوابت العامة
  static const String appName = 'سوق الأدوية بالجملة';
  static const String appVersion = '2.0.0';
  
  // إعدادات التخزين المؤقت
  static const Duration cacheDuration = Duration(minutes: 5);
  
  // إعدادات الصفحات
  static const int pageSize = 20;
  static const int maxRecentItems = 10;
  
  // أنماط التاريخ
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // إعدادات الصور
  static const double imageMaxWidth = 1024;
  static const double imageMaxHeight = 1024;
  static const int imageQuality = 85;
  
  // حالات الطلب
  static const List<String> orderStatuses = [
    'pending',
    'accepted', 
    'shipped',
    'delivered',
    'rejected',
  ];
  
  static const Map<String, String> orderStatusLabels = {
    'pending': 'قيد المراجعة',
    'accepted': 'تم القبول',
    'shipped': 'تم الشحن',
    'delivered': 'تم التسليم',
    'rejected': 'مرفوض',
  };
  
  static const Map<String, Color> orderStatusColors = {
    'pending': Colors.orange,
    'accepted': Colors.blue,
    'shipped': Colors.purple,
    'delivered': Colors.green,
    'rejected': Colors.red,
  };
  
  // أنواع الدفع
  static const List<String> paymentTypes = ['cash', 'credit'];
  static const Map<String, String> paymentTypeLabels = {
    'cash': 'نقدي',
    'credit': 'آجل',
  };
  
  // وسائل الدفع
  static const List<String> paymentMethods = ['transfer', 'wallet', 'cash_on_delivery'];
  static const Map<String, String> paymentMethodLabels = {
    'transfer': 'حوالة بنكية',
    'wallet': 'محفظة إلكترونية',
    'cash_on_delivery': 'كاش عند الاستلام',
  };
  
  // ==================== العملات (موحدة) ====================
  static const String currencyYer = 'yemen';
  static const String currencySar = 'saudi';
  static const String currencyUsd = 'dollar';
  
  static const List<String> supportedCurrencies = [currencyYer, currencySar, currencyUsd];
  
  static const Map<String, String> currencySymbols = {
    currencyYer: 'ر.ي',
    currencySar: 'ر.س',
    currencyUsd: '\$',
  };
  
  static const Map<String, String> currencyNames = {
    currencyYer: 'ريال يمني',
    currencySar: 'ريال سعودي',
    currencyUsd: 'دولار أمريكي',
  };
  
  /// الحصول على رمز العملة
  static String getCurrencySymbol(String currency) {
    return currencySymbols[currency] ?? 'ر.ي';
  }
  
  /// الحصول على اسم العملة
  static String getCurrencyName(String currency) {
    return currencyNames[currency] ?? 'ريال يمني';
  }
  
  /// التحقق من صحة العملة
  static bool isValidCurrency(String currency) {
    return supportedCurrencies.contains(currency);
  }
  
  /// العملة الأساسية (الريال اليمني)
  static String getBaseCurrency() => currencyYer;
  
  /// هل العملة هي العملة الأساسية؟
  static bool isBaseCurrency(String currency) => currency == currencyYer;
  
  // ==================== أنواع المستخدمين ====================
  static const String userTypeCompany = 'company';
  static const String userTypePharmacy = 'pharmacy';
  static const String userTypeSubAccount = 'sub_account';
  
  // صيغ التصدير
  static const List<String> exportFormats = ['pdf', 'excel', 'csv', 'image'];
  static const Map<String, String> exportFormatLabels = {
    'pdf': 'PDF',
    'excel': 'Excel',
    'csv': 'CSV',
    'image': 'صورة',
  };
}