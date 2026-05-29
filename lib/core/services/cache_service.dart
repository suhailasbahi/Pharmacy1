// lib/core/services/cache_service.dart
import 'dart:collection';

class CacheService<K, V> {
  final int maxSize;
  final Duration ttl;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  
  CacheService({
    this.maxSize = 50,
    this.ttl = const Duration(minutes: 5),
  });
  
  /// إضافة عنصر إلى الكاش
  void put(K key, V value) {
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = _CacheEntry(value: value, timestamp: DateTime.now());
  }
  
  /// الحصول على عنصر من الكاش (إذا لم ينتهِ صلاحيته)
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    final isExpired = DateTime.now().difference(entry.timestamp) > ttl;
    if (isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }
  
  /// التحقق من وجود عنصر في الكاش
  bool contains(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    final isExpired = DateTime.now().difference(entry.timestamp) > ttl;
    if (isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }
  
  /// إزالة عنصر من الكاش
  void remove(K key) {
    _cache.remove(key);
  }
  
  /// مسح جميع العناصر من الكاش
  void clear() {
    _cache.clear();
  }
  
  /// الحصول على حجم الكاش
  int get size => _cache.length;
  
  /// الحصول على جميع المفاتيح (غير منتهية الصلاحية)
  Iterable<K> get keys sync* {
    for (var key in _cache.keys) {
      if (contains(key)) {
        yield key;
      }
    }
  }
  
  /// الحصول على جميع القيم (غير منتهية الصلاحية)
  Iterable<V> get values sync* {
    for (var entry in _cache.entries) {
      if (contains(entry.key)) {
        yield entry.value.value;
      }
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;
  
  _CacheEntry({required this.value, required this.timestamp});
}

/// نسخة متخصصة لتخزين الطلبات
class OrdersCache extends CacheService<String, List<dynamic>> {
  OrdersCache() : super(maxSize: 20, ttl: const Duration(minutes: 5));
  
  String _buildKey(String companyId, String? branchId, String? period) {
    return '${companyId}_${branchId ?? 'all'}_${period ?? 'all'}';
  }
  
  void putOrders(String companyId, String? branchId, String? period, List<dynamic> orders) {
    put(_buildKey(companyId, branchId, period), orders);
  }
  
  List<dynamic>? getOrders(String companyId, String? branchId, String? period) {
    return get(_buildKey(companyId, branchId, period));
  }
}

/// نسخة متخصصة لتخزين المنتجات
class ProductsCache extends CacheService<String, List<dynamic>> {
  ProductsCache() : super(maxSize: 30, ttl: const Duration(minutes: 10));
  
  void putProducts(String companyId, List<dynamic> products) {
    put(companyId, products);
  }
  
  List<dynamic>? getProducts(String companyId) {
    return get(companyId);
  }
}