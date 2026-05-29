//lib/data/repositories/order_repository.dart';

import '../datasources/remote/firebase_service.dart';
import '../datasources/models/order_model.dart';

class OrderRepository {
  final FirebaseService _firebase =
      FirebaseService();

  Future<List<OrderModel>> getOrdersForCompany(
  String companyId, {
  String? branchId,
}) async {
  Map<String, dynamic> where = {
    'companyId': companyId,
  };

  if (branchId != null && branchId.isNotEmpty) {
    where['branchId'] = branchId;
  }

  // ✅ لا تستخدم orderBy في Firebase
  final data = await _firebase.getCollection(
    'orders',
    where: where,
    // orderBy: {'date': false},  // ❌ علق هذا السطر
  );

  final orders = data
      .map((json) => OrderModel.fromMap(json['id'], json))
      .toList();
  
  // ✅ قم بالترتيب محلياً
  orders.sort((a, b) => b.date.compareTo(a.date));
  
  return orders;
}

  Future<List<OrderModel>> getOrdersForPharmacy(
    String pharmacyId,
  ) async {
    final data = await _firebase.getCollection(
      'orders',
      where: {
        'pharmacyId': pharmacyId,
      },
      orderBy: {'date': false},
    );

    return data
        .map(
          (json) => OrderModel.fromMap(
            json['id'],
            json,
          ),
        )
        .toList();
  }

  Future<void> createOrder(
    OrderModel order,
  ) async {
    await _firebase.setDocument(
      'orders',
      order.id,
      order.toMap(),
    );
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
  }) async {
    await _firebase.updateDocument(
      'orders',
      orderId,
      {
        'status': status,
        'rejectionReason': rejectionReason,
      },
    );
  }

  Future<void> updateOrderItems(
    String orderId,
    List<OrderItem> items,
    double totalPrice,
  ) async {
    await _firebase.updateDocument(
      'orders',
      orderId,
      {
        'items':
            items.map((i) => i.toMap()).toList(),
        'totalPrice': totalPrice,
      },
    );
  }

  Stream<List<OrderModel>>
      streamOrdersForCompany(
    String companyId, {
    String? branchId,
  }) {
    Map<String, dynamic> where = {
      'companyId': companyId,
    };

    if (branchId != null) {
      where['branchId'] = branchId;
    }

    return _firebase
        .streamCollection(
          'orders',
          where: where,
        )
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data =
            doc.data() as Map<String, dynamic>;

        return OrderModel.fromMap(
          doc.id,
          data,
        );
      }).toList();
    });
  }
}