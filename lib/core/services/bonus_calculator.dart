// lib/core/services/bonus_calculator.dart
import '../../data/datasources/models/bonus_model.dart';
import '../../data/datasources/models/cart_item.dart';
import '../../data/datasources/models/product_model.dart';

class BonusCalculator {
  /// حساب نسبة البونص للمنتج
  static double getBonusPercentage({
    required BonusModel? bonusCash,
    required BonusModel? bonusCredit,
    required bool isCashOrder,
  }) {
    if (isCashOrder && bonusCash != null) return bonusCash.percentage;
    if (!isCashOrder && bonusCredit != null) return bonusCredit.percentage;
    return 0;
  }
  
  /// حساب نسبة البونص من المنتج
  static double getProductBonusPercentage(ProductModel product, bool isCashOrder) {
    if (isCashOrder && product.bonusCash != null) {
      return product.bonusCash!.percentage;
    }
    if (!isCashOrder && product.bonusCredit != null) {
      return product.bonusCredit!.percentage;
    }
    return 0;
  }
  
  /// حساب عدد قطع البونص
  static int calculateBonusPieces({
    required int totalPieces,
    required double bonusPercentage,
  }) {
    if (bonusPercentage <= 0) return 0;
    return (totalPieces * bonusPercentage / 100).floor();
  }
  
  /// حساب البونص لعنصر في السلة
  static int calculateItemBonus({
    required CartItem item,
    required bool isCashOrder,
  }) {
    final percentage = getBonusPercentage(
      bonusCash: item.bonusCashPercentage != null 
          ? BonusModel(percentage: item.bonusCashPercentage!, forCashOnly: true)
          : null,
      bonusCredit: item.bonusCreditPercentage != null
          ? BonusModel(percentage: item.bonusCreditPercentage!, forCashOnly: false)
          : null,
      isCashOrder: isCashOrder,
    );
    
    return calculateBonusPieces(
      totalPieces: item.totalPieces,
      bonusPercentage: percentage,
    );
  }
  
  /// حساب البونص لمنتج معين
  static int calculateProductBonus({
    required ProductModel product,
    required int quantity,
    required String unit,
    required bool isCashOrder,
  }) {
    final percentage = getProductBonusPercentage(product, isCashOrder);
    if (percentage <= 0) return 0;
    
    final piecesPerCarton = product.piecesPerCarton;
    final totalPieces = unit == 'carton' 
        ? quantity * piecesPerCarton 
        : quantity;
    
    return calculateBonusPieces(
      totalPieces: totalPieces,
      bonusPercentage: percentage,
    );
  }
  
  /// تحديث البونص لجميع عناصر الشركة
  static void updateCompanyBonuses({
    required List<CartItem> items,
    required String companyId,
    required bool isCashOrder,
  }) {
    for (var item in items) {
      if (item.companyId == companyId) {
        item.bonus = calculateItemBonus(item: item, isCashOrder: isCashOrder);
      }
    }
  }
  
  /// تحديث البونص لجميع العناصر
  static void updateAllBonuses({
    required List<CartItem> items,
    required bool isCashOrder,
  }) {
    for (var item in items) {
      item.bonus = calculateItemBonus(item: item, isCashOrder: isCashOrder);
    }
  }
  
  /// الحصول على أفضل بونص (أعلى نسبة بين النقدي والآجل)
  static double getMaxBonusPercentage(ProductModel product) {
    final cashBonus = product.bonusCash?.percentage ?? 0;
    final creditBonus = product.bonusCredit?.percentage ?? 0;
    return cashBonus > creditBonus ? cashBonus : creditBonus;
  }
  
  /// هل المنتج يقدم بونص؟
  static bool hasBonus(ProductModel product) {
    return (product.bonusCash?.percentage ?? 0) > 0 ||
           (product.bonusCredit?.percentage ?? 0) > 0;
  }
  
  /// نص البونص للت display
  static String getBonusDisplayText(ProductModel product, {bool isCashOrder = true}) {
    final percentage = getProductBonusPercentage(product, isCashOrder);
    if (percentage <= 0) return '';
    
    final type = isCashOrder ? 'نقدي' : 'آجل';
    return 'بونص $type: $percentage%';
  }
}