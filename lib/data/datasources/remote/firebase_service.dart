// lib/data/datasources/remote/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // جلب مجموعة كاملة
  Future<List<Map<String, dynamic>>> getCollection(
  String collectionName, {
  Map<String, dynamic>? where,
  Map<String, bool>? orderBy,
  int? limit,
}) async {
  Query query = _firestore.collection(collectionName);
  
  if (where != null) {
    where.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });
  }
  
  // ✅ فقط إذا كان orderBy موجوداً وغير فارغ
  if (orderBy != null && orderBy.isNotEmpty) {
    orderBy.forEach((key, descending) {
      query = query.orderBy(key, descending: descending);
    });
  }
  
  if (limit != null) {
    query = query.limit(limit);
  }
  
  final snapshot = await query.get();
  return snapshot.docs.map((doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    data['id'] = doc.id;
    return data;
  }).toList();
}

  // جلب وثيقة واحدة
  Future<Map<String, dynamic>?> getDocument(String collectionName, String docId) async {
    final doc = await _firestore.collection(collectionName).doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  // إضافة وثيقة
  Future<void> setDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(docId).set(data);
  }

  // تحديث وثيقة
  Future<void> updateDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(docId).update(data);
  }

  // حذف وثيقة
  Future<void> deleteDocument(String collectionName, String docId) async {
    await _firestore.collection(collectionName).doc(docId).delete();
  }

  // Stream لوثيقة (لـ real-time)
  Stream<DocumentSnapshot> streamDocument(String collectionName, String docId) {
    return _firestore.collection(collectionName).doc(docId).snapshots();
  }

  // Stream لمجموعة
  Stream<QuerySnapshot> streamCollection(String collectionName, {Map<String, dynamic>? where}) {
    Query query = _firestore.collection(collectionName);
    if (where != null) {
      where.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }
    return query.snapshots();
  }
}