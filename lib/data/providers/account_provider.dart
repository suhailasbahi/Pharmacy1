// lib/data/providers/account_provider.dart
import 'package:flutter/material.dart';
import '../repositories/account_repository.dart';
import '../datasources/models/account_model.dart';
import '../../core/services/balance_calculator.dart';
import '../../core/services/snackbar_service.dart';
import 'package:app/core/exports.dart';

class AccountProvider extends ChangeNotifier {
  final AccountRepository _repository = AccountRepository();
  List<CustomerAccount> _customers = [];
  List<SupplierAccount> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerAccount> get customers => _customers;
  List<SupplierAccount> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== CUSTOMER ====================
  
  Future<void> loadCustomersForCompany(String companyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _repository.getCustomersForCompany(companyId);
    } catch (e) {
      _error = e.toString();
      SnackBarService.showError('حدث خطأ في تحميل العملاء: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerAccount?> getOrCreateCustomer({
    required String pharmacyId,
    required String pharmacyName,
    required String companyId,
    required String currency,
    String? branchId,
    String phone = '',
  }) async {
    final existing = await _repository.getCustomerByPharmacyAndCompanyAndCurrency(
      pharmacyId: pharmacyId,
      companyId: companyId,
      currency: currency,
    );
    if (existing != null) return existing;

    final newCustomer = CustomerAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      phone: phone,
      balance: 0,
      currency: currency,
      createdAt: DateTime.now(),
      branchId: branchId,
      companyId: companyId,
    );
    
    await _repository.addCustomer(newCustomer);
    _customers.add(newCustomer);
    notifyListeners();
    
    return newCustomer;
  }

  // ==================== SUPPLIER ====================
  
  Future<void> loadSuppliersForPharmacy(String pharmacyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _suppliers = await _repository.getSuppliersForPharmacy(pharmacyId);
    } catch (e) {
      _error = e.toString();
      SnackBarService.showError('حدث خطأ في تحميل الموردين: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SupplierAccount?> getOrCreateSupplier({
    required String companyId,
    required String companyName,
    required String pharmacyId,
    required String currency,
    String phone = '',
  }) async {
    final existing = await _repository.getSupplierByCompanyAndPharmacyAndCurrency(
      companyId: companyId,
      pharmacyId: pharmacyId,
      currency: currency,
    );
    if (existing != null) return existing;

    final newSupplier = SupplierAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: companyId,
      companyName: companyName,
      phone: phone,
      balance: 0,
      currency: currency,
      createdAt: DateTime.now(),
      pharmacyId: pharmacyId,
    );
    
    await _repository.addSupplier(newSupplier);
    _suppliers.add(newSupplier);
    notifyListeners();
    
    return newSupplier;
  }

  // ==================== LEDGER ====================
  
  Future<double> getAccountBalance(String accountId) async {
    return await _repository.getBalance(accountId);
  }

  Future<List<LedgerTransaction>> getAccountTransactions(String accountId) async {
    return await _repository.getTransactions(accountId);
  }
  
  /// الحصول على الرصيد الجاري مع التفاصيل
  Future<List<RunningBalanceEntry>> getRunningBalance(String accountId) async {
    final transactions = await getAccountTransactions(accountId);
    return BalanceCalculator.calculateRunningBalance(transactions);
  }

  Future<void> createOrderLedgerEntry({
    required String orderId,
    required String accountId,
    required String accountType,
    required double amount,
    required String currency,
    required String direction,
    required String companyId,
    required String pharmacyId,
  }) async {
    final type = direction == 'payment' ? 'credit' : 'debit';
    final note = direction == 'sale' 
        ? 'مبيعات آجل - الطلب #${orderId.substring(0, 8)}'
        : direction == 'purchase'
            ? 'مشتريات آجل - الطلب #${orderId.substring(0, 8)}'
            : 'سداد دفعة - الطلب #${orderId.substring(0, 8)}';
    
    await _repository.addLedgerEntry(
      accountId: accountId,
      accountType: accountType,
      type: type,
      amount: amount,
      currency: currency,
      orderId: orderId,
      note: note,
      companyId: companyId,
      pharmacyId: pharmacyId,
    );
  }

  // ==================== دوال حسابات العملاء (جديدة) ====================
  
  /// الحصول على الرصيد الإجمالي للعملاء (مع فلترة البحث)
  double getTotalCustomersBalance({String searchQuery = ''}) {
    var customers = _customers;
    if (searchQuery.isNotEmpty) {
      customers = customers.where((c) =>
        c.pharmacyName.toLowerCase().contains(searchQuery.toLowerCase()) ||
        c.phone.contains(searchQuery)
      ).toList();
    }
    return BalanceCalculator.calculateTotalCustomersBalance(customers);
  }
  
  /// الحصول على العملاء مع فلترة البحث
  List<CustomerAccount> getFilteredCustomers(String searchQuery) {
    if (searchQuery.isEmpty) return _customers;
    return _customers.where((c) =>
      c.pharmacyName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      c.phone.contains(searchQuery)
    ).toList();
  }
  
  /// الحصول على رصيد عميل معين
  Future<double> getCustomerBalance(String customerId) async {
    return await getAccountBalance(customerId);
  }
  
  // ==================== دوال حسابات الموردين (جديدة) ====================
  
  /// الحصول على الرصيد الإجمالي للموردين (مع فلترة البحث)
  double getTotalSuppliersBalance({String searchQuery = ''}) {
    var suppliers = _suppliers;
    if (searchQuery.isNotEmpty) {
      suppliers = suppliers.where((s) =>
        s.companyName.toLowerCase().contains(searchQuery.toLowerCase()) ||
        s.phone.contains(searchQuery)
      ).toList();
    }
    return BalanceCalculator.calculateTotalSuppliersBalance(suppliers);
  }
  
  /// الحصول على الموردين مع فلترة البحث
  List<SupplierAccount> getFilteredSuppliers(String searchQuery) {
    if (searchQuery.isEmpty) return _suppliers;
    return _suppliers.where((s) =>
      s.companyName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      s.phone.contains(searchQuery)
    ).toList();
  }
  
  /// الحصول على رصيد مورد معين
  Future<double> getSupplierBalance(String supplierId) async {
    return await getAccountBalance(supplierId);
  }
  
  /// الحصول على كشف حساب عميل (مع فلترة التاريخ)
  Future<List<RunningBalanceEntry>> getCustomerStatement(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getRunningBalance(customerId);
    
    if (startDate == null && endDate == null) return transactions;
    
    return transactions.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }
  
  /// الحصول على ملخص كشف حساب عميل
  Future<Map<String, double>> getCustomerStatementSummary(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getCustomerStatement(customerId, startDate: startDate, endDate: endDate);
    
    final totalPurchases = transactions.fold(0.0, (sum, t) => sum + t.debit);
    final totalPayments = transactions.fold(0.0, (sum, t) => sum + t.credit);
    final currentBalance = transactions.isNotEmpty ? transactions.last.balance : 0;
    
    return {
      'totalPurchases': totalPurchases,
      'totalPayments': totalPayments,
      'currentBalance': currentBalance.toDouble(),
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}