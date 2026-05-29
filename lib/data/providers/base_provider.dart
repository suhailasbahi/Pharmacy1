// lib/data/providers/base_provider.dart
import 'package:flutter/material.dart';

/// Base Provider لتوحيد الـ Providers وتقليل تكرار الكود
abstract class BaseProvider<T> extends ChangeNotifier {
  List<T> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  
  // ==================== Getters ====================
  
  List<T> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get hasError => _error != null;
  bool get hasSuccess => _successMessage != null;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get count => _items.length;
  
  // ==================== Setters ====================
  
  @protected
  set items(List<T> value) {
    _items = value;
    notifyListeners();
  }
  
  @protected
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  @protected
  set error(String? value) {
    _error = value;
    if (value != null) {
      _successMessage = null;
    }
    notifyListeners();
  }
  
  @protected
  set successMessage(String? value) {
    _successMessage = value;
    if (value != null) {
      _error = null;
    }
    notifyListeners();
  }
  
  // ==================== Actions ====================
  
  /// تنفيذ عملية مع التعامل مع الأخطاء والحالة
  @protected
  Future<void> safeCall(Future<void> Function() action, {String? successMsg}) async {
    isLoading = true;
    clearError();
    clearSuccess();
    
    try {
      await action();
      if (successMsg != null) {
        successMessage = successMsg;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }
  
  /// إضافة عنصر واحد
  @protected
  void addItem(T item) {
    _items.add(item);
    notifyListeners();
  }
  
  /// إضافة عناصر متعددة
  @protected
  void addAllItems(Iterable<T> items) {
    _items.addAll(items);
    notifyListeners();
  }
  
  /// تحديث عنصر
  @protected
  void updateItem(int index, T item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      notifyListeners();
    }
  }
  
  /// تحديث عنصر حسب المعرف
  @protected
  void updateItemWhere(bool Function(T) where, T Function(T) updater) {
    for (var i = 0; i < _items.length; i++) {
      if (where(_items[i])) {
        _items[i] = updater(_items[i]);
        notifyListeners();
        break;
      }
    }
  }
  
  /// حذف عنصر
  @protected
  void removeItem(T item) {
    _items.remove(item);
    notifyListeners();
  }
  
  /// حذف عنصر حسب المعرف
  @protected
  void removeItemWhere(bool Function(T) where) {
    _items.removeWhere(where);
    notifyListeners();
  }
  
  /// حذف عنصر حسب index
  @protected
  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }
  
  /// مسح جميع العناصر
  @protected
  void clearItems() {
    _items.clear();
    notifyListeners();
  }
  
  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// مسح رسالة النجاح
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }
  
  /// مسح كل شيء
  void clearAll() {
    _items.clear();
    _error = null;
    _successMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  /// الحصول على عنصر حسب index
  T? getItemAt(int index) {
    if (index >= 0 && index < _items.length) {
      return _items[index];
    }
    return null;
  }
  
  /// البحث عن عنصر
  T? findItem(bool Function(T) where) {
    try {
      return _items.firstWhere(where);
    } catch (e) {
      return null;
    }
  }
  
  /// هل يحتوي على عنصر
  bool contains(bool Function(T) where) {
    return _items.any(where);
  }
}

/// Base Provider مع دعم الـ Stream
abstract class BaseStreamProvider<T> extends BaseProvider<T> {
  Stream<List<T>>? _stream;
  StreamSubscription<List<T>>? _subscription;
  
  @protected
  void initializeStream(Stream<List<T>> stream) {
    _stream = stream;
    _subscription = _stream?.listen((data) {
      items = data;
      isLoading = false;
      error = null;
    }, onError: (e) {
      error = e.toString();
      isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}