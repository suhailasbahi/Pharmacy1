// lib/data/datasources/remote/query_optimizer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QueryOptimizer {
  // قائمة الـ Indexes المطلوبة في Firebase Console
  static const List<String> requiredIndexes = [
    'orders: companyId + date',
    'orders: pharmacyId + date',
    'orders: companyId + branchId + date',
    'orders: companyId + status + date',
    'products: companyId + isActive',
    'products: agencyId + isActive',
    'users: parentCompanyId + userType',
    'users: branchId + userType',
  ];
  
  /// تحسين استعلام الطلبات للشركة
  static Query optimizeCompanyOrdersQuery(
    Query query,
    String companyId, {
    String? branchId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var optimized = query
        .where('companyId', isEqualTo: companyId)
        .orderBy('date', descending: true);
    
    if (branchId != null && branchId.isNotEmpty) {
      optimized = optimized.where('branchId', isEqualTo: branchId);
    }
    
    if (status != null && status.isNotEmpty) {
      optimized = optimized.where('status', isEqualTo: status);
    }
    
    if (startDate != null) {
      optimized = optimized.where('date', isGreaterThanOrEqualTo: startDate);
    }
    
    if (endDate != null) {
      optimized = optimized.where('date', isLessThanOrEqualTo: endDate);
    }
    
    return optimized;
  }
  
  /// تحسين استعلام الطلبات للصيدلية
  static Query optimizePharmacyOrdersQuery(
    Query query,
    String pharmacyId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var optimized = query
        .where('pharmacyId', isEqualTo: pharmacyId)
        .orderBy('date', descending: true);
    
    if (status != null && status.isNotEmpty) {
      optimized = optimized.where('status', isEqualTo: status);
    }
    
    if (startDate != null) {
      optimized = optimized.where('date', isGreaterThanOrEqualTo: startDate);
    }
    
    if (endDate != null) {
      optimized = optimized.where('date', isLessThanOrEqualTo: endDate);
    }
    
    return optimized;
  }
  
  /// إضافة Pagination إلى الاستعلام
  static Query paginateQuery(
    Query query, {
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) {
    var paginated = query.limit(limit);
    if (lastDocument != null) {
      paginated = paginated.startAfterDocument(lastDocument);
    }
    return paginated;
  }
  
  /// تحسين استعلام المنتجات
  static Query optimizeProductsQuery(
    Query query,
    String companyId, {
    String? agencyId,
    bool onlyActive = true,
    String? searchQuery,
  }) {
    var optimized = query
        .where('companyId', isEqualTo: companyId);
    
    if (onlyActive) {
      optimized = optimized.where('isActive', isEqualTo: true);
    }
    
    if (agencyId != null && agencyId.isNotEmpty) {
      optimized = optimized.where('agencyId', isEqualTo: agencyId);
    }
    
    // البحث (يتطلب index مخصص)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // للبحث النصي، نستخدم startAt/endAt أو Firebase Extensions
      optimized = optimized
          .orderBy('name')
          .startAt([searchQuery])
          .endAt(['$searchQuery\uf8ff']);
    }
    
    return optimized;
  }
  
  /// تحسين استعلام المستخدمين الفرعيين
  static Query optimizeSubAccountsQuery(
    Query query,
    String parentCompanyId, {
    String? branchId,
    String? roleId,
  }) {
    var optimized = query
        .where('parentCompanyId', isEqualTo: parentCompanyId)
        .where('userType', isEqualTo: 'sub_account');
    
    if (branchId != null && branchId.isNotEmpty) {
      optimized = optimized.where('branchId', isEqualTo: branchId);
    }
    
    if (roleId != null && roleId.isNotEmpty) {
      optimized = optimized.where('roleId', isEqualTo: roleId);
    }
    
    return optimized;
  }
  
  /// الحصول على استعلام محدود (للكاش)
  static Query limitedQuery(Query query, {int limit = 50}) {
    return query.limit(limit);
  }
}