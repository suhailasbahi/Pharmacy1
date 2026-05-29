// lib/core/utils/performance_monitor.dart
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _metrics = {};
  static bool _isEnabled = kDebugMode;
  
  static void enable() => _isEnabled = true;
  static void disable() => _isEnabled = false;
  
  /// بدء تتبع وقت عملية
  static void startTimer(String name) {
    if (!_isEnabled) return;
    _timers[name] = Stopwatch()..start();
  }
  
  /// إنهاء تتبع وقت عملية وتسجيل النتيجة
  static void endTimer(String name, {bool log = true}) {
    if (!_isEnabled) return;
    
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      final elapsed = timer.elapsedMilliseconds;
      
      if (log) {
        debugPrint('⏱️ $name: ${elapsed}ms');
      }
      
      _recordMetric(name, elapsed);
      _timers.remove(name);
    }
  }
  
  /// تنفيذ عملية مع تتبع وقتها
  static Future<T> measure<T>(String name, Future<T> Function() action) async {
    if (!_isEnabled) return await action();
    
    startTimer(name);
    try {
      return await action();
    } finally {
      endTimer(name);
    }
  }
  
  /// تسجيل مقياس
  static void _recordMetric(String name, int value) {
    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }
    _metrics[name]!.add(value);
    
    // الاحتفاظ بآخر 100 قياس فقط
    if (_metrics[name]!.length > 100) {
      _metrics[name]!.removeAt(0);
    }
  }
  
  /// الحصول على إحصائيات لعملية معينة
  static Map<String, dynamic>? getStats(String name) {
    final values = _metrics[name];
    if (values == null || values.isEmpty) return null;
    
    values.sort();
    final sum = values.reduce((a, b) => a + b);
    final average = sum / values.length;
    final min = values.first;
    final max = values.last;
    
    return {
      'count': values.length,
      'average': average,
      'min': min,
      'max': max,
    };
  }
  
  /// طباعة جميع الإحصائيات
  static void printAllStats() {
    if (!_isEnabled) return;
    
    debugPrint('📊 === Performance Stats ===');
    for (var entry in _metrics.entries) {
      final stats = getStats(entry.key);
      if (stats != null) {
        debugPrint('  ${entry.key}: avg=${stats['average']}ms, min=${stats['min']}ms, max=${stats['max']}ms (${stats['count']} samples)');
      }
    }
  }
  
  /// مسح جميع البيانات
  static void clear() {
    _timers.clear();
    _metrics.clear();
  }
}