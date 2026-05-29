// lib/core/services/balance_calculator.dart
import '../../data/datasources/models/account_model.dart';

class BalanceCalculator {
  /// حساب الرصيد من المعاملات
  static double calculateBalance(List<LedgerTransaction> transactions) {
    double balance = 0;
    for (var t in transactions) {
      if (t.type == 'debit') {  // مدين (مشتريات)
        balance += t.amount;
      } else {  // دائن (مدفوعات)
        balance -= t.amount;
      }
    }
    return balance;
  }
  
  /// حساب إجمالي المشتريات
  static double calculateTotalPurchases(List<LedgerTransaction> transactions) {
    return transactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  /// حساب إجمالي المدفوعات
  static double calculateTotalPayments(List<LedgerTransaction> transactions) {
    return transactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  /// حساب الرصيد الجاري (running balance) مع تفصيل كل معاملة
  static List<RunningBalanceEntry> calculateRunningBalance(
    List<LedgerTransaction> transactions,
  ) {
    final sorted = List<LedgerTransaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    double runningBalance = 0;
    final result = <RunningBalanceEntry>[];
    
    for (var t in sorted) {
      if (t.type == 'debit') {
        runningBalance += t.amount;
        result.add(RunningBalanceEntry(
          date: t.date,
          description: t.note,
          debit: t.amount,
          credit: 0,
          balance: runningBalance,
        ));
      } else {
        runningBalance -= t.amount;
        result.add(RunningBalanceEntry(
          date: t.date,
          description: t.note,
          debit: 0,
          credit: t.amount,
          balance: runningBalance,
        ));
      }
    }
    
    return result;
  }
  
  /// حساب الرصيد الإجمالي لجميع العملاء
  static double calculateTotalCustomersBalance(List<CustomerAccount> customers) {
    return customers.fold(0.0, (sum, c) => sum + c.balance);
  }
  
  /// حساب الرصيد الإجمالي لجميع الموردين
  static double calculateTotalSuppliersBalance(List<SupplierAccount> suppliers) {
    return suppliers.fold(0.0, (sum, s) => sum + s.balance);
  }
  
  /// عدد العملاء الذين عليهم رصيد
  static int countCustomersWithBalance(List<CustomerAccount> customers) {
    return customers.where((c) => c.balance > 0).length;
  }
  
  /// عدد العملاء الذين ليس عليهم رصيد
  static int countCustomersWithoutBalance(List<CustomerAccount> customers) {
    return customers.where((c) => c.balance <= 0).length;
  }
  
  /// أعلى رصيد عميل
  static CustomerAccount? getHighestBalanceCustomer(List<CustomerAccount> customers) {
    if (customers.isEmpty) return null;
    return customers.reduce((a, b) => a.balance > b.balance ? a : b);
  }
  
  /// أعلى رصيد مورد
  static SupplierAccount? getHighestBalanceSupplier(List<SupplierAccount> suppliers) {
    if (suppliers.isEmpty) return null;
    return suppliers.reduce((a, b) => a.balance > b.balance ? a : b);
  }
}

/// نموذج لإدخال الرصيد الجاري
class RunningBalanceEntry {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double balance;
  
  RunningBalanceEntry({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });
}