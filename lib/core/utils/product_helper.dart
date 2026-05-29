// lib/core/utils/product_helper.dart
import 'package:flutter/material.dart';
import '../../data/datasources/models/product_model.dart';
import '../constants/app_constants.dart';
import '../extensions/num_extensions.dart';

class ProductHelper {
  /// الحصول على السعر النهائي للمنتج مع الخصم
  static double getFinalPrice(ProductModel product, String regionId) {
    return product.getFinalPriceForRegion(regionId);
  }
  
  /// الحصول على السعر الأصلي للمنتج
  static double getOriginalPrice(ProductModel product, String regionId) {
    return product.getOriginalPriceForRegion(regionId);
  }
  
  /// حساب نسبة الخصم
  static int getDiscountPercentage(ProductModel product, String regionId) {
    final original = getOriginalPrice(product, regionId);
    final finalPrice = getFinalPrice(product, regionId);
    if (original <= 0 || finalPrice >= original) return 0;
    return ((original - finalPrice) / original * 100).toInt();
  }
  
  /// هل المنتج عليه عرض؟
  static bool hasOffer(ProductModel product, String regionId) {
    return product.hasOfferForRegion(regionId);
  }
  
  /// الحصول على رمز العملة
  static String getCurrencySymbol(ProductModel product, String regionId) {
    final currency = product.getCurrencyForRegion(regionId);
    return AppConstants.getCurrencySymbol(currency);
  }
  
  /// الحصول على نص السعر للعرض
  static String getPriceText(ProductModel product, String regionId) {
    final price = getFinalPrice(product, regionId);
    final symbol = getCurrencySymbol(product, regionId);
    final unit = product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت';
    return '${price.formatPrice()} $symbol / $unit';
  }
  
  /// الحصول على نص السعر مع العرض
  static Map<String, String> getPriceWithOfferText(ProductModel product, String regionId) {
    final hasOfferFlag = hasOffer(product, regionId);
    if (!hasOfferFlag) {
      return {
        'current': getPriceText(product, regionId),
        'original': '',
      };
    }
    
    final finalPrice = getFinalPrice(product, regionId);
    final originalPrice = getOriginalPrice(product, regionId);
    final symbol = getCurrencySymbol(product, regionId);
    final unit = product.defaultUnit == 'carton' ? 'كرتون' : 'باكيت';
    
    return {
      'current': '${finalPrice.formatPrice()} $symbol / $unit',
      'original': '${originalPrice.formatPrice()} $symbol / $unit',
    };
  }
  
  /// فلترة المنتجات حسب البحث والتصنيف
  static List<ProductModel> filterProducts({
    required List<ProductModel> products,
    String searchQuery = '',
    String selectedCategory = 'الكل',
    required String regionId,
  }) {
    return products.where((product) {
      if (!product.isActive) return false;
      
      // فلترة البحث
      bool matchesSearch = searchQuery.isEmpty ||
          product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.scientificName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.companyName.toLowerCase().contains(searchQuery.toLowerCase());
      
      // فلترة التصنيف
      final category = getCategoryFromName(product.name);
      bool matchesCategory = selectedCategory == 'الكل' || category == selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }
  
  /// الحصول على قائمة التصنيفات من المنتجات
  static List<String> getCategoriesFromProducts(List<ProductModel> products) {
    final Set<String> categories = {'الكل'};
    for (var product in products) {
      if (product.isActive) {
        categories.add(_getCategoryFromName(product.name));
      }
    }
    return categories.toList();
  }
  
  /// الحصول على التصنيف من اسم المنتج
  static String _getCategoryFromName(String name) {
    if (name.contains('بنادول') || name.contains('بروفين') || name.contains('ديكلوفيناك')) {
      return 'مسكنات';
    } else if (name.contains('أموكسيل') || name.contains('زيتروماكس')) {
      return 'مضادات حيوية';
    } else if (name.contains('فيتامين')) {
      return 'فيتامينات';
    }
    return 'أدوية';
  }
  
  /// الحصول على لون التصنيف
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'مسكنات': return Colors.red.shade400;
      case 'مضادات حيوية': return Colors.blue.shade400;
      case 'فيتامينات': return Colors.green.shade400;
      default: return Colors.teal.shade400;
    }
  }
  
  /// الحصول على أيقونة التصنيف
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'مسكنات': return Icons.medication;
      case 'مضادات حيوية': return Icons.biotech;
      case 'فيتامينات': return Icons.circle;
      default: return Icons.medical_information;
    }
  }
   
  // ==================== دوال إدارة المنتجات ====================
  
  /// فلترة منتجات الشركة حسب البحث
  static List<ProductModel> filterCompanyProducts(
    List<ProductModel> products,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return products;
    return products.where((p) =>
      p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
      p.scientificName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      p.concentration.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }
  
  /// الحصول على السعر الافتراضي لمنتج (للعرض في القائمة)
  static double getSamplePrice(ProductModel product) {
    return product.regionPrices.isNotEmpty ? product.regionPrices.first.price : 0;
  }
  
  /// الحصول على رمز العملة الافتراضي للمنتج
  static String getSampleCurrencySymbol(ProductModel product) {
    if (product.regionPrices.isEmpty) return 'ر.ي';
    final currency = product.regionPrices.first.currency;
    return AppConstants.getCurrencySymbol(currency);
  }
  
  /// هل المنتج يقدم بونص نقدي؟
  static bool hasCashBonus(ProductModel product) {
    return (product.bonusCash?.percentage ?? 0) > 0;
  }
  
  /// هل المنتج يقدم بونص آجل؟
  static bool hasCreditBonus(ProductModel product) {
    return (product.bonusCredit?.percentage ?? 0) > 0;
  }
  
  /// الحصول على نسبة البونص النقدي
  static double getCashBonusPercentage(ProductModel product) {
    return product.bonusCash?.percentage ?? 0;
  }
  
  /// الحصول على نسبة البونص الآجل
  static double getCreditBonusPercentage(ProductModel product) {
    return product.bonusCredit?.percentage ?? 0;
  }
  
  /// هل المنتج عليه عرض عام؟
  static bool hasGlobalOffer(ProductModel product) {
    return product.hasOffer && product.offerPrice != null;
  }
  
  /// الحصول على سعر العرض العام
  static double? getGlobalOfferPrice(ProductModel product) {
    return product.offerPrice;
  }
  
  /// الحصول على نص البونص للعرض
  static String getBonusDisplayText(ProductModel product) {
    final cashBonus = getCashBonusPercentage(product);
    final creditBonus = getCreditBonusPercentage(product);
    
    if (cashBonus > 0 && creditBonus > 0) {
      return 'بونص نقدي: $cashBonus% | آجل: $creditBonus%';
    } else if (cashBonus > 0) {
      return 'بونص نقدي: $cashBonus%';
    } else if (creditBonus > 0) {
      return 'بونص آجل: $creditBonus%';
    }
    return '';
  }
  
  /// الحصول على لون حالة المخزون
  static Color getStockColor(int stockQuantity) {
    if (stockQuantity <= 0) return Colors.red;
    if (stockQuantity < 10) return Colors.orange;
    return Colors.green;
  }
  
  /// الحصول على نص حالة المخزون
  static String getStockText(int stockQuantity) {
    if (stockQuantity <= 0) return 'غير متوفر';
    if (stockQuantity < 10) return 'متبقي $stockQuantity فقط';
    return 'متوفر';
  }

}