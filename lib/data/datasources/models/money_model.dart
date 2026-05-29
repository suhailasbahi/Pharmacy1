// lib/data/datasources/models/money_model.dart
import '../../../core/constants/app_constants.dart';

class MoneyModel {
  final double amount;
  final String currency;  // yemen, saudi, dollar (موحدة)
  final double exchangeRate;
  final double baseAmount;

  const MoneyModel({
    required this.amount,
    required this.currency,
    required this.exchangeRate,
    required this.baseAmount,
  });

  factory MoneyModel.fromMap(Map<String, dynamic> map) {
    String currency = map['currency'] ?? AppConstants.currencyYer;
    // توحيد العملة إذا كانت بصيغة قديمة
    if (currency == 'YER') currency = AppConstants.currencyYer;
    if (currency == 'SAR') currency = AppConstants.currencySar;
    
    return MoneyModel(
      amount: (map['amount'] ?? 0).toDouble(),
      currency: currency,
      exchangeRate: (map['exchangeRate'] ?? 1).toDouble(),
      baseAmount: (map['baseAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'baseAmount': baseAmount,
    };
  }

  MoneyModel copyWith({
    double? amount,
    String? currency,
    double? exchangeRate,
    double? baseAmount,
  }) {
    return MoneyModel(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      baseAmount: baseAmount ?? this.baseAmount,
    );
  }
  
  String get currencySymbol => AppConstants.getCurrencySymbol(currency);
  String get currencyName => AppConstants.getCurrencyName(currency);
}