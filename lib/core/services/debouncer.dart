// lib/core/services/debouncer.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/material.dart';
/// خدمة منع التنفيذ المتكرر (مثلاً للبحث)
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// تنفيذ الإجراء بعد انتهاء فترة الانتظار
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// إلغاء التنفيذ المعلق
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// تنظيف الموارد
  void dispose() {
    cancel();
  }
  
  /// هل يوجد تنفيذ معلق؟
  bool get isPending => _timer?.isActive ?? false;
}

/// نسخة متقدمة مع دعم القيم (للبحث)
class ValueDebouncer<T> {
  final Duration delay;
  Timer? _timer;
  T? _lastValue;
  void Function(T)? _callback;

  ValueDebouncer({this.delay = const Duration(milliseconds: 500)});

  /// تنفيذ الإجراء مع القيمة بعد انتهاء فترة الانتظار
  void call(T value, void Function(T) callback) {
    _callback = callback;
    _lastValue = value;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (_callback != null && _lastValue != null) {
        _callback!(_lastValue!);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _lastValue = null;
    _callback = null;
  }
  
  void dispose() {
    cancel();
  }
}