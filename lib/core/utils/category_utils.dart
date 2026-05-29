// lib/core/utils/category_utils.dart
import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final Color color;
  final IconData icon;
  final List<String> keywords;
  
  const CategoryInfo({
    required this.name,
    required this.color,
    required this.icon,
    required this.keywords,
  });
}

class CategoryUtils {
  static const Map<String, CategoryInfo> categories = {
    'مسكنات': CategoryInfo(
      name: 'مسكنات',
      color: Colors.red,
      icon: Icons.medication,
      keywords: ['بنادول', 'بروفين', 'ديكلوفيناك', 'باراسيتامول', 'إيبوبروفين', 'مسكن'],
    ),
    'مضادات حيوية': CategoryInfo(
      name: 'مضادات حيوية',
      color: Colors.blue,
      icon: Icons.biotech,
      keywords: ['أموكسيل', 'زيتروماكس', 'أموكسيسيلين', 'أزيثروميسين', 'مضاد حيوي'],
    ),
    'فيتامينات': CategoryInfo(
      name: 'فيتامينات',
      color: Colors.green,
      icon: Icons.circle,
      keywords: ['فيتامين', 'مكمل غذائي', 'سنتروم'],
    ),
    'مكملات': CategoryInfo(
      name: 'مكملات',
      color: Colors.orange,
      icon: Icons.fitness_center,
      keywords: ['مكمل', 'بروتين', 'كرياتين'],
    ),
    'ضغط الدم': CategoryInfo(
      name: 'ضغط الدم',
      color: Colors.purple,
      icon: Icons.favorite,
      keywords: ['ضغط', 'لضغط', 'ارتفاع ضغط'],
    ),
    'السكري': CategoryInfo(
      name: 'السكري',
      color: Colors.indigo,
      icon: Icons.bloodtype,
      keywords: ['سكري', 'أنسولين', 'سكر'],
    ),
    'حساسية': CategoryInfo(
      name: 'حساسية',
      color: Colors.pink,
      icon: Icons.air,
      keywords: ['حساسية', 'حساسيه', 'كلاريتين'],
    ),
    'جهاز هضمي': CategoryInfo(
      name: 'جهاز هضمي',
      color: Colors.brown,
      icon: Icons.restaurant,
      keywords: ['هضم', 'معدة', 'قولون', 'عسر هضم'],
    ),
    'أطفال': CategoryInfo(
      name: 'أطفال',
      color: Colors.cyan,
      icon: Icons.child_care,
      keywords: ['أطفال', 'رضع', 'اطفال'],
    ),
  };

  static const CategoryInfo defaultCategory = CategoryInfo(
    name: 'أدوية',
    color: Colors.teal,
    icon: Icons.medical_information,
    keywords: [],
  );

  /// الحصول على تصنيف المنتج من اسمه
  static CategoryInfo getCategoryFromName(String name) {
    final lowerName = name.toLowerCase();
    
    for (var category in categories.values) {
      for (var keyword in category.keywords) {
        if (lowerName.contains(keyword.toLowerCase())) {
          return category;
        }
      }
    }
    
    return defaultCategory;
  }
  
  /// الحصول على لون التصنيف
  static Color getCategoryColor(String categoryName) {
    final category = categories[categoryName];
    return category?.color ?? defaultCategory.color;
  }
  
  /// الحصول على أيقونة التصنيف
  static IconData getCategoryIcon(String categoryName) {
    final category = categories[categoryName];
    return category?.icon ?? defaultCategory.icon;
  }
  
  /// قائمة بجميع التصنيفات
  static List<String> get allCategoryNames => categories.keys.toList();
  
  /// قائمة بجميع التصنيفات مع "الكل" في البداية
  static List<String> get filterCategories => ['الكل', ...allCategoryNames];
}