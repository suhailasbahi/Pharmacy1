// lib/core/extensions/num_extensions.dart
import 'package:flutter/material.dart';

extension NumExtensions on num {
  /// تنسيق السعر (ألف, مليون)
  String formatPrice() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}م';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(0)}أ';
    }
    return toStringAsFixed(0);
  }
  
  /// تنسيق الرقم (K, M)
  String formatNumber() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
  
  /// تحويل إلى نسبة مئوية
  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }
  
  /// إضافة صفر في البداية إذا كان الرقم أقل من 10
  String toTwoDigits() {
    if (this < 10) return '0$this';
    return toString();
  }
  
  /// تنسيق العملة (فاصل آلاف)
  String formatCurrency({String? symbol, int decimals = 2}) {
    final value = toStringAsFixed(decimals);
    final parts = value.split('.');
    final integerPart = _addThousandSeparator(parts[0]);
    
    if (decimals > 0 && parts.length > 1) {
      return '$integerPart.${parts[1]}${symbol != null ? ' $symbol' : ''}';
    }
    return '$integerPart${symbol != null ? ' $symbol' : ''}';
  }
  
  String _addThousandSeparator(String number) {
    final buffer = StringBuffer();
    final length = number.length;
    
    for (var i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    
    return buffer.toString();
  }
  
  /// الحصول على لون بناءً على القيمة (أحمر للأرقام السالبة، أخضر للموجبة)
  Color getSignColor() {
    if (this < 0) return Colors.red;
    if (this > 0) return Colors.green;
    return Colors.grey;
  }
  
  /// هل القيمة موجبة؟
  bool get isPositive => this > 0;
  
  /// هل القيمة سالبة؟
  bool get isNegative => this < 0;
  
  /// هل القيمة صفر؟
  bool get isZero => this == 0;
}