// lib/core/services/statistics_calculator.dart

import 'package:flutter/material.dart';

class StatisticsCalculator {
  /// حساب النسبة المئوية
  static double calculatePercentage(double part, double total) {
    if (total <= 0) return 0;
    return (part / total) * 100;
  }
  
  /// حساب النمو بين فترتين
  static double calculateGrowth(double current, double previous) {
    if (previous <= 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }
  
  /// الحصول على مؤشر النمو (سهم لأعلى/لأسفل)
  static IconData getGrowthIcon(double growth) {
    if (growth > 0) return Icons.trending_up;
    if (growth < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }
  
  /// الحصول على لون النمو
  static Color getGrowthColor(double growth) {
    if (growth > 0) return Colors.green;
    if (growth < 0) return Colors.red;
    return Colors.grey;
  }
  
  /// حساب المتوسط الحسابي
  static double calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  /// حساب المتوسط المرجح
  static double calculateWeightedAverage(List<double> values, List<double> weights) {
    if (values.isEmpty || values.length != weights.length) return 0;
    
    double sum = 0;
    double weightSum = 0;
    
    for (var i = 0; i < values.length; i++) {
      sum += values[i] * weights[i];
      weightSum += weights[i];
    }
    
    return weightSum > 0 ? sum / weightSum : 0;
  }
  
  /// حساب الوسيط
  static double calculateMedian(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle];
  }
  
  /// حساب المنوال (القيمة الأكثر تكراراً)
  static List<double> calculateMode(List<double> values) {
    if (values.isEmpty) return [];
    
    final frequency = <double, int>{};
    for (var v in values) {
      frequency[v] = (frequency[v] ?? 0) + 1;
    }
    
    final maxFreq = frequency.values.reduce((a, b) => a > b ? a : b);
    return frequency.entries
        .where((e) => e.value == maxFreq)
        .map((e) => e.key)
        .toList();
  }
  
  /// حساب الانحراف المعياري
  static double calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = calculateAverage(values);
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean)).toList();
    final variance = calculateAverage(squaredDiffs);
    return variance > 0 ? variance : 0;
  }
  
  /// حساب معامل الاختلاف (CV)
  static double calculateCV(List<double> values) {
    final mean = calculateAverage(values);
    if (mean == 0) return 0;
    final stdDev = calculateStdDev(values);
    return (stdDev / mean) * 100;
  }
  
  /// ترتيب القائمة وتحديد المراكز
  static List<RankedItem<T>> rankItems<T>({
    required List<T> items,
    required double Function(T) valueGetter,
    bool ascending = false,
  }) {
    final ranked = items.map((item) => RankedItem(
      item: item,
      value: valueGetter(item),
    )).toList();
    
    ranked.sort((a, b) => ascending 
        ? a.value.compareTo(b.value) 
        : b.value.compareTo(a.value));
    
    for (var i = 0; i < ranked.length; i++) {
      ranked[i].rank = i + 1;
    }
    
    return ranked;
  }
  
  /// حساب التوزيع التكراري
  static Map<String, int> calculateFrequency<T>(List<T> items, String Function(T) keyGetter) {
    final result = <String, int>{};
    for (var item in items) {
      final key = keyGetter(item);
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }
  
  /// حساب الاتجاه (زيادة/نقصان)
  static String getTrend(List<double> values) {
    if (values.length < 2) return 'مستقر';
    
    int increases = 0;
    int decreases = 0;
    
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[i - 1]) increases++;
      else if (values[i] < values[i - 1]) decreases++;
    }
    
    if (increases > decreases * 1.5) return 'متزايد';
    if (decreases > increases * 1.5) return 'متناقص';
    return 'مستقر';
  }
}

class RankedItem<T> {
  final T item;
  final double value;
  int rank = 0;
  
  RankedItem({required this.item, required this.value});
}