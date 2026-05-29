// lib/data/datasources/remote/batch_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// قراءة مستندات متعددة في طلب واحد (موازي)
  Future<Map<String, Map<String, dynamic>>> getMultipleDocuments(
    String collectionName,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    
    // Firestore limit is 10 documents per batch get
    final results = <String, Map<String, dynamic>>{};
    
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);
      
      final futures = chunk.map((id) async {
        final doc = await _firestore.collection(collectionName).doc(id).get();
        if (doc.exists) {
          results[id] = doc.data()!;
        }
      });
      
      await Future.wait(futures);
    }
    
    return results;
  }
  
  /// تحديث عدة مستندات دفعة واحدة
  Future<void> batchUpdate(
    String collectionName,
    List<MapEntry<String, Map<String, dynamic>>> updates,
  ) async {
    if (updates.isEmpty) return;
    
    final batch = _firestore.batch();
    
    for (var update in updates) {
      final ref = _firestore.collection(collectionName).doc(update.key);
      batch.update(ref, update.value);
    }
    
    await batch.commit();
  }
  
  /// إنشاء عدة مستندات دفعة واحدة
  Future<void> batchCreate(
    String collectionName,
    List<MapEntry<String, Map<String, dynamic>>> creates,
  ) async {
    if (creates.isEmpty) return;
    
    final batch = _firestore.batch();
    
    for (var create in creates) {
      final ref = _firestore.collection(collectionName).doc(create.key);
      batch.set(ref, create.value);
    }
    
    await batch.commit();
  }
  
  /// حذف عدة مستندات دفعة واحدة
  Future<void> batchDelete(
    String collectionName,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return;
    
    final batch = _firestore.batch();
    
    for (var id in ids) {
      final ref = _firestore.collection(collectionName).doc(id);
      batch.delete(ref);
    }
    
    await batch.commit();
  }
  
  /// إنشاء طلب مع تحديث المخزون دفعة واحدة
  Future<void> createOrderWithStockUpdate({
    required Map<String, dynamic> orderData,
    required List<MapEntry<String, int>> stockUpdates,
    required String orderId,
  }) async {
    final batch = _firestore.batch();
    
    // 1. إضافة الطلب
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.set(orderRef, orderData);
    
    // 2. تحديث المخزون
    for (var update in stockUpdates) {
      final productRef = _firestore.collection('products').doc(update.key);
      batch.update(productRef, {
        'stockQuantity': FieldValue.increment(-update.value),
      });
    }
    
    await batch.commit();
  }
  
  /// إنشاء دفعة مع قيد محاسبي
  Future<void> createPaymentWithLedger({
    required Map<String, dynamic> paymentData,
    required Map<String, dynamic> ledgerData,
    required String paymentId,
    required String ledgerId,
  }) async {
    final batch = _firestore.batch();
    
    final paymentRef = _firestore.collection('payments').doc(paymentId);
    batch.set(paymentRef, paymentData);
    
    final ledgerRef = _firestore.collection('ledger_transactions').doc(ledgerId);
    batch.set(ledgerRef, ledgerData);
    
    await batch.commit();
  }
}