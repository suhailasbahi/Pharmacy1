// lib/modules/reports/data/report_repository.dart
import '../../../data/datasources/remote/firebase_service.dart';
import '../../../data/datasources/models/order_model.dart';
import '../../../data/datasources/models/product_model.dart';
import '../../../data/datasources/models/account_model.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/services/cache_service.dart';
import 'package:app/core/utils/date_filter_type.dart';
import 'package:app/core/utils/date_filter_helper.dart';

class ReportRepository {
  final FirebaseService _firebase = FirebaseService();
  final OrdersCache _ordersCache = OrdersCache();
  final ProductsCache _productsCache = ProductsCache();
  
  // ==================== ORDERS ====================
  
  /// جلب طلبات الشركة
  Future<List<OrderModel>> getCompanyOrders({
    required String companyId,
    String? branchId,
    DateFilterType? dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
    List<String>? statuses,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildOrdersCacheKey(
      type: 'company',
      id: companyId,
      branchId: branchId,
      dateFilter: dateFilter,
      customStart: customStart,
      customEnd: customEnd,
      statuses: statuses,
    );
    
    if (!forceRefresh && _ordersCache.contains(cacheKey)) {
      final cached = _ordersCache.get(cacheKey);
      if (cached != null) return cached.cast<OrderModel>();
    }
    
    // بناء الاستعلام
    Map<String, dynamic> where = {'companyId': companyId};
    if (branchId != null && branchId.isNotEmpty) {
      where['branchId'] = branchId;
    }
    
    var data = await _firebase.getCollection('orders', where: where);
    var orders = data.map((json) => OrderModel.fromMap(json['id'], json)).toList();
    
    // فلترة حسب التاريخ
    if (dateFilter != null) {
      final range = DateFilterHelper.getRange(
        dateFilter,
        customStart: customStart,
        customEnd: customEnd,
      );
      orders = orders.where((o) => 
        o.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
        o.date.isBefore(range.end.add(const Duration(days: 1)))
      ).toList();
    }
    
    // فلترة حسب الحالة
    if (statuses != null && statuses.isNotEmpty) {
      orders = orders.where((o) => statuses.contains(o.status)).toList();
    }
    
    // ترتيب تنازلي
    orders.sort((a, b) => b.date.compareTo(a.date));
    
    _ordersCache.put(cacheKey, orders);
    return orders;
  }
  
  /// جلب طلبات الصيدلية
  Future<List<OrderModel>> getPharmacyOrders({
    required String pharmacyId,
    DateFilterType? dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
    List<String>? statuses,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildOrdersCacheKey(
      type: 'pharmacy',
      id: pharmacyId,
      dateFilter: dateFilter,
      customStart: customStart,
      customEnd: customEnd,
      statuses: statuses,
    );
    
    if (!forceRefresh && _ordersCache.contains(cacheKey)) {
      final cached = _ordersCache.get(cacheKey);
      if (cached != null) return cached.cast<OrderModel>();
    }
    
    var data = await _firebase.getCollection('orders', where: {'pharmacyId': pharmacyId});
    var orders = data.map((json) => OrderModel.fromMap(json['id'], json)).toList();
    
    if (dateFilter != null) {
      final range = DateFilterHelper.getRange(
        dateFilter,
        customStart: customStart,
        customEnd: customEnd,
      );
      orders = orders.where((o) => 
        o.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
        o.date.isBefore(range.end.add(const Duration(days: 1)))
      ).toList();
    }
    
    if (statuses != null && statuses.isNotEmpty) {
      orders = orders.where((o) => statuses.contains(o.status)).toList();
    }
    
    orders.sort((a, b) => b.date.compareTo(a.date));
    
    _ordersCache.put(cacheKey, orders);
    return orders;
  }
  
  // ==================== PRODUCTS ====================
  
  /// جلب منتجات الشركة
  Future<List<ProductModel>> getCompanyProducts(
    String companyId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _productsCache.contains(companyId)) {
      final cached = _productsCache.get(companyId);
      if (cached != null) return cached.cast<ProductModel>();
    }
    
    final data = await _firebase.getCollection(
      'products',
      where: {'companyId': companyId, 'isActive': true},
    );
    
    final products = data.map((json) => ProductModel.fromMap(json['id'], json)).toList();
    _productsCache.put(companyId, products);
    
    return products;
  }
  
  /// جلب منتج بواسطة ID
  Future<ProductModel?> getProductById(String productId) async {
    final data = await _firebase.getDocument('products', productId);
    if (data == null) return null;
    return ProductModel.fromMap(productId, data);
  }
  
  // ==================== CUSTOMERS ====================
  
  /// جلب عملاء الشركة
  Future<List<CustomerAccount>> getCompanyCustomers(String companyId) async {
    final data = await _firebase.getCollection(
      'customer_accounts',
      where: {'companyId': companyId},
    );
    
    return data.map((json) => CustomerAccount.fromMap(json['id'], json)).toList();
  }
  
  /// جلب عميل بواسطة ID
  Future<CustomerAccount?> getCustomerById(String customerId) async {
    final data = await _firebase.getDocument('customer_accounts', customerId);
    if (data == null) return null;
    return CustomerAccount.fromMap(customerId, data);
  }
  
  // ==================== SUPPLIERS ====================
  
  /// جلب موردي الصيدلية
  Future<List<SupplierAccount>> getPharmacySuppliers(String pharmacyId) async {
    final data = await _firebase.getCollection(
      'supplier_accounts',
      where: {'pharmacyId': pharmacyId},
    );
    
    return data.map((json) => SupplierAccount.fromMap(json['id'], json)).toList();
  }
  
  /// جلب مورد بواسطة ID
  Future<SupplierAccount?> getSupplierById(String supplierId) async {
    final data = await _firebase.getDocument('supplier_accounts', supplierId);
    if (data == null) return null;
    return SupplierAccount.fromMap(supplierId, data);
  }
  
  // ==================== TRANSACTIONS ====================
  
  /// جلب معاملات حساب
  Future<List<LedgerTransaction>> getAccountTransactions(String accountId) async {
    final data = await _firebase.getCollection(
      'ledger_transactions',
      where: {'accountId': accountId},
    );
    
    return data.map((json) => LedgerTransaction.fromMap(json)).toList();
  }
  
  // ==================== HELPERS ====================
  
  String _buildOrdersCacheKey({
    required String type,
    required String id,
    String? branchId,
    DateFilterType? dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
    List<String>? statuses,
  }) {
    final parts = [type, id];
    if (branchId != null) parts.add(branchId);
    if (dateFilter != null) parts.add(dateFilter.toString());
    if (customStart != null) parts.add(customStart.toIso8601String());
    if (customEnd != null) parts.add(customEnd.toIso8601String());
    if (statuses != null) parts.add(statuses.join(','));
    return parts.join('_');
  }
  
  /// مسح الكاش
  void clearCache() {
    _ordersCache.clear();
    _productsCache.clear();
  }
  
  /// مسح كاش الطلبات
  void clearOrdersCache() {
    _ordersCache.clear();
  }
  
  /// مسح كاش المنتجات
  void clearProductsCache() {
    _productsCache.clear();
  }
}