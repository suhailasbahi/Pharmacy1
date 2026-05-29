// lib/data/providers/order_provider.dart
import 'package:flutter/material.dart';
import '../repositories/order_repository.dart';
import '../datasources/models/order_model.dart';
import '../../core/services/snackbar_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrdersForCompany(
    String companyId, {
    String? branchId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _repository.getOrdersForCompany(
        companyId,
        branchId: branchId,
      );
    } catch (e) {
      _error = e.toString();
      SnackBarService.showError('حدث خطأ في تحميل الطلبات: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrdersForPharmacy(String pharmacyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _repository.getOrdersForPharmacy(pharmacyId);
    } catch (e) {
      _error = e.toString();
      SnackBarService.showError('حدث خطأ في تحميل الطلبات: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<OrderModel>> getOrdersForCompany(
    String companyId, {
    String? branchId,
  }) async {
    return await _repository.getOrdersForCompany(companyId, branchId: branchId);
  }

  Future<List<OrderModel>> getOrdersForPharmacy(String pharmacyId) async {
    return await _repository.getOrdersForPharmacy(pharmacyId);
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await _repository.createOrder(order);
      _orders.insert(0, order);
      notifyListeners();
      SnackBarService.showSuccess('تم إنشاء الطلب بنجاح');
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
      rethrow;
    }
  }

  Future<void> addOrders(OrderModel order) async {
    await createOrder(order);
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      await _repository.updateOrderStatus(orderId, status, rejectionReason: rejectionReason);

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = _orders[index];
        _orders[index] = OrderModel(
          id: old.id,
          pharmacyId: old.pharmacyId,
          pharmacyName: old.pharmacyName,
          pharmacyCity: old.pharmacyCity,
          regionId: old.regionId,
          companyId: old.companyId,
          companyName: old.companyName,
          items: old.items,
          totalPrice: old.totalPrice,
          currency: old.currency,
          exchangeRate: old.exchangeRate,
          status: status,
          date: old.date,
          paymentType: old.paymentType,
          paymentMethod: old.paymentMethod,
          creditDays: old.creditDays,
          rejectionReason: rejectionReason,
          createdBy: old.createdBy,
          assignedTo: old.assignedTo,
          branchId: old.branchId,
        );
        notifyListeners();
      }
      
      SnackBarService.showSuccess('تم تحديث حالة الطلب');
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
      rethrow;
    }
  }

  Future<void> acceptOrder(String orderId, dynamic accountProvider) async {
    await updateOrderStatus(orderId, 'accepted');
  }

  Future<void> rejectOrder(String orderId, String reason, dynamic accountProvider) async {
    await updateOrderStatus(orderId, 'rejected', rejectionReason: reason);
  }

  Future<void> updateOrderItems(
    String orderId,
    List<OrderItem> items,
    double totalPrice,
  ) async {
    try {
      await _repository.updateOrderItems(orderId, items, totalPrice);

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = _orders[index];
        _orders[index] = OrderModel(
          id: old.id,
          pharmacyId: old.pharmacyId,
          pharmacyName: old.pharmacyName,
          pharmacyCity: old.pharmacyCity,
          regionId: old.regionId,
          companyId: old.companyId,
          companyName: old.companyName,
          items: items,
          totalPrice: totalPrice,
          currency: old.currency,
          exchangeRate: old.exchangeRate,
          status: old.status,
          date: old.date,
          paymentType: old.paymentType,
          paymentMethod: old.paymentMethod,
          creditDays: old.creditDays,
          rejectionReason: old.rejectionReason,
          createdBy: old.createdBy,
          assignedTo: old.assignedTo,
          branchId: old.branchId,
        );
        notifyListeners();
      }
      
      SnackBarService.showSuccess('تم تحديث الطلب بنجاح');
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
      rethrow;
    }
  }

  Stream<List<OrderModel>> streamOrdersForCompany(
    String companyId, {
    String? branchId,
  }) {
    return _repository.streamOrdersForCompany(companyId, branchId: branchId);
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}