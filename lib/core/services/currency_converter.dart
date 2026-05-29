// lib/core/services/currency_converter.dart
import '../../data/services/exchange_rate_service.dart';
import '../../core/constants/app_constants.dart';

class CurrencyConverter {
  /// تحويل مبلغ من عملة إلى أخرى
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;
    return ExchangeRateService.convert(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
  }
  
  /// تحويل مبلغ وتقريب النتيجة
  static double convertAndRound({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    int decimals = 2,
  }) {
    final result = convert(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
    return double.parse(result.toStringAsFixed(decimals));
  }
  
  /// الحصول على سعر الصرف بين عملتين
  static double getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return 1.0;
    return ExchangeRateService.getExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
  }
  
  /// تنسيق المبلغ مع العملة
  static String formatAmount({
    required double amount,
    required String currency,
    bool showSymbol = true,
    int decimals = 2,
  }) {
    final symbol = showSymbol ? AppConstants.getCurrencySymbol(currency) : '';
    final formattedAmount = amount.toStringAsFixed(decimals);
    return showSymbol ? '$formattedAmount $symbol' : formattedAmount;
  }
  
  /// تنسيق المبلغ مع سعر الصرف
  static String formatConversion({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    int decimals = 2,
  }) {
    final converted = convertAndRound(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      decimals: decimals,
    );
    final fromSymbol = AppConstants.getCurrencySymbol(fromCurrency);
    final toSymbol = AppConstants.getCurrencySymbol(toCurrency);
    return '$amount $fromSymbol = $converted $toSymbol';
  }
  
  /// الحصول على رمز العملة
  static String getSymbol(String currency) {
    return AppConstants.getCurrencySymbol(currency);
  }
  
  /// التحقق من صحة العملة
  static bool isValidCurrency(String currency) {
    return AppConstants.isValidCurrency(currency);
  }
  
  /// الحصول على العملة الأساسية
  static String getBaseCurrency() => AppConstants.getBaseCurrency();
  
  /// هل العملة هي العملة الأساسية؟
  static bool isBaseCurrency(String currency) => AppConstants.isBaseCurrency(currency);
}