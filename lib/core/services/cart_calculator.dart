// lib/core/services/cart_calculator.dart
import '../../data/datasources/models/cart_item.dart';

class CartCalculator {
  /// حساب إجمالي السلة
  static double calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  /// حساب إجمالي الكمية
  static int calculateTotalQuantity(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
  
  /// حساب إجمالي البونص
  static int calculateTotalBonus(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.bonus);
  }
  
  /// حساب إجمالي القطع (باكيتات)
  static int calculateTotalPieces(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.totalPieces);
  }
  
  /// حساب عدد العناصر الفريدة
  static int calculateItemCount(List<CartItem> items) {
    return items.length;
  }
  
  /// تجميع العناصر حسب الشركة
  static Map<String, List<CartItem>> groupByCompany(List<CartItem> items) {
    final result = <String, List<CartItem>>{};
    for (var item in items) {
      if (!result.containsKey(item.companyId)) {
        result[item.companyId] = [];
      }
      result[item.companyId]!.add(item);
    }
    return result;
  }
  
  /// تجميع العناصر حسب الشركة والعملة
  static Map<String, List<CartItem>> groupByCompanyAndCurrency(List<CartItem> items) {
    final result = <String, List<CartItem>>{};
    for (var item in items) {
      final key = '${item.companyId}_${item.currency}';
      if (!result.containsKey(key)) {
        result[key] = [];
      }
      result[key]!.add(item);
    }
    return result;
  }
  
  /// حساب إجمالي كل شركة
  static Map<String, double> calculateCompanyTotals(List<CartItem> items) {
    final result = <String, double>{};
    for (var item in items) {
      result[item.companyId] = (result[item.companyId] ?? 0) + item.totalPrice;
    }
    return result;
  }
  
  /// حساب إجمالي كل عملة
  static Map<String, double> calculateCurrencyTotals(List<CartItem> items) {
    final result = <String, double>{};
    for (var item in items) {
      result[item.currency] = (result[item.currency] ?? 0) + item.totalPrice;
    }
    return result;
  }
  
  /// التحقق من الحد الأدنى للطلب
  static bool isBelowMinOrder(CartItem item, {bool isCashOrder = true}) {
    final minAllowed = item.unit == 'carton' 
        ? (item.minOrderQuantity / item.piecesPerCarton).ceil()
        : item.minOrderQuantity;
    return item.quantity < minAllowed;
  }
  
  /// الحصول على الحد الأدنى المسموح لعنصر
  static int getMinAllowedQuantity(CartItem item) {
    return item.unit == 'carton' 
        ? (item.minOrderQuantity / item.piecesPerCarton).ceil()
        : item.minOrderQuantity;
  }
  
  /// تطبيق الحد الأدنى على الكمية
  static int applyMinQuantity(CartItem item, int quantity) {
    final minAllowed = getMinAllowedQuantity(item);
    return quantity < minAllowed ? minAllowed : quantity;
  }
  
  /// تغيير الوحدة وحساب الكمية الجديدة
  static int convertQuantityForUnitChange(CartItem item, String newUnit) {
    if (item.unit == newUnit) return item.quantity;
    if (item.piecesPerCarton <= 0) return item.quantity;
    
    if (item.unit == 'piece' && newUnit == 'carton') {
      return (item.quantity / item.piecesPerCarton).ceil();
    } else if (item.unit == 'carton' && newUnit == 'piece') {
      return item.quantity * item.piecesPerCarton;
    }
    return item.quantity;
  }
  
  /// نص ملخص السلة
  static String getSummaryText(List<CartItem> items) {
    final itemCount = items.length;
    final totalQuantity = calculateTotalQuantity(items);
    final totalPrice = calculateTotal(items);
    
    return '${itemCount} منتج، ${totalQuantity} قطعة، ${totalPrice.toStringAsFixed(2)}';
  }
    
  /// حساب السعر بعد تغيير الوحدة
  static double calculatePriceAfterUnitChange({
    required double currentPrice,
    required String currentUnit,
    required String newUnit,
    required int piecesPerCarton,
  }) {
    if (currentUnit == newUnit) return currentPrice;
    
    if (currentUnit == 'piece' && newUnit == 'carton') {
      return currentPrice * piecesPerCarton;
    } else if (currentUnit == 'carton' && newUnit == 'piece') {
      return currentPrice / piecesPerCarton;
    }
    return currentPrice;
  }
  
  /// حساب الكمية بعد تغيير الوحدة
  static int calculateQuantityAfterUnitChange({
    required int currentQuantity,
    required String currentUnit,
    required String newUnit,
    required int piecesPerCarton,
  }) {
    if (currentUnit == newUnit) return currentQuantity;
    
    if (currentUnit == 'piece' && newUnit == 'carton') {
      return (currentQuantity / piecesPerCarton).ceil();
    } else if (currentUnit == 'carton' && newUnit == 'piece') {
      return currentQuantity * piecesPerCarton;
    }
    return currentQuantity;
  }

    
}