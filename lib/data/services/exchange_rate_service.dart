import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String _sarToYerKey = 'sar_to_yer_rate';
  static const String _usdToYerKey = 'usd_to_yer_rate';
  
  static const String currencyYer = 'yemen';
  static const String currencySar = 'saudi';
  static const String currencyUsd = 'dollar';
  
  static List<String> get supportedCurrencies => [currencyYer, currencySar, currencyUsd];
  
  static double _sarToYerRate = 150.0;
  static double _usdToYerRate = 500.0;
  
  static double get sarToYerRate => _sarToYerRate;
  static double get usdToYerRate => _usdToYerRate;
  static double get yerToSarRate => 1 / _sarToYerRate;
  static double get yerToUsdRate => 1 / _usdToYerRate;
  static double get usdToSarRate => _usdToYerRate / _sarToYerRate;
  static double get sarToUsdRate => _sarToYerRate / _usdToYerRate;
  
  static Future<void> loadRates() async {
    final prefs = await SharedPreferences.getInstance();
    _sarToYerRate = prefs.getDouble(_sarToYerKey) ?? 150.0;
    _usdToYerRate = prefs.getDouble(_usdToYerKey) ?? 500.0;
  }
  
  static Future<void> updateRates({double? sarToYer, double? usdToYer}) async {
    if (sarToYer != null && sarToYer > 0) _sarToYerRate = sarToYer;
    if (usdToYer != null && usdToYer > 0) _usdToYerRate = usdToYer;
    final prefs = await SharedPreferences.getInstance();
    if (sarToYer != null) await prefs.setDouble(_sarToYerKey, _sarToYerRate);
    if (usdToYer != null) await prefs.setDouble(_usdToYerKey, _usdToYerRate);
  }
  
  static double getExchangeRate({required String fromCurrency, required String toCurrency}) {
    if (fromCurrency == toCurrency) return 1.0;
    if (fromCurrency == currencyYer && toCurrency == currencySar) return yerToSarRate;
    if (fromCurrency == currencySar && toCurrency == currencyYer) return _sarToYerRate;
    if (fromCurrency == currencyYer && toCurrency == currencyUsd) return yerToUsdRate;
    if (fromCurrency == currencyUsd && toCurrency == currencyYer) return _usdToYerRate;
    if (fromCurrency == currencySar && toCurrency == currencyUsd) return sarToUsdRate;
    if (fromCurrency == currencyUsd && toCurrency == currencySar) return usdToSarRate;
    return 1.0;
  }
  
  static double convert({required double amount, required String fromCurrency, required String toCurrency}) {
    if (fromCurrency == toCurrency) return amount;
    return amount * getExchangeRate(fromCurrency: fromCurrency, toCurrency: toCurrency);
  }
  
  static String getSymbol(String currency) {
    switch (currency) {
      case currencySar: return 'ر.س';
      case currencyUsd: return '\$';
      default: return 'ر.ي';
    }
  }
}