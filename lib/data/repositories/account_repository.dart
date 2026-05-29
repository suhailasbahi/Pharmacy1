//lib/data/repositories/account_repository.dart';

import '../datasources/remote/firebase_service.dart';
import '../datasources/models/account_model.dart';

class AccountRepository {
  final FirebaseService _firebase =
      FirebaseService();

  // ================= CUSTOMER =================

  Future<List<CustomerAccount>>
      getCustomersForCompany(
    String companyId,
  ) async {
    final data = await _firebase.getCollection(
      'customer_accounts',
      where: {
        'companyId': companyId,
      },
    );

    return data
        .map(
          (json) => CustomerAccount.fromMap(
            json['id'],
            json,
          ),
        )
        .toList();
  }

  Future<CustomerAccount?>
      getCustomerByPharmacyAndCompanyAndCurrency({
    required String pharmacyId,
    required String companyId,
    required String currency,
  }) async {
    final data = await _firebase.getCollection(
      'customer_accounts',
      where: {
        'pharmacyId': pharmacyId,
        'companyId': companyId,
        'currency': currency,
      },
      limit: 1,
    );

    if (data.isEmpty) return null;

    return CustomerAccount.fromMap(
      data.first['id'],
      data.first,
    );
  }

  Future<void> addCustomer(
    CustomerAccount customer,
  ) async {
    await _firebase.setDocument(
      'customer_accounts',
      customer.id,
      customer.toMap(),
    );
  }

  // ================= SUPPLIER =================

  Future<List<SupplierAccount>>
      getSuppliersForPharmacy(
    String pharmacyId,
  ) async {
    final data = await _firebase.getCollection(
      'supplier_accounts',
      where: {
        'pharmacyId': pharmacyId,
      },
    );

    return data
        .map(
          (json) => SupplierAccount.fromMap(
            json['id'],
            json,
          ),
        )
        .toList();
  }

  Future<SupplierAccount?>
      getSupplierByCompanyAndPharmacyAndCurrency({
    required String companyId,
    required String pharmacyId,
    required String currency,
  }) async {
    final data = await _firebase.getCollection(
      'supplier_accounts',
      where: {
        'companyId': companyId,
        'pharmacyId': pharmacyId,
        'currency': currency,
      },
      limit: 1,
    );

    if (data.isEmpty) return null;

    return SupplierAccount.fromMap(
      data.first['id'],
      data.first,
    );
  }

  Future<void> addSupplier(
    SupplierAccount supplier,
  ) async {
    await _firebase.setDocument(
      'supplier_accounts',
      supplier.id,
      supplier.toMap(),
    );
  }

  // ================= LEDGER =================

  Future<List<LedgerTransaction>>
      getTransactions(
    String accountId,
  ) async {
    final data = await _firebase.getCollection(
      'ledger_transactions',
      where: {
        'accountId': accountId,
      },
    );

    return data
        .map(
          (json) =>
              LedgerTransaction.fromMap(json),
        )
        .toList();
  }

  Future<double> getBalance(
    String accountId,
  ) async {
    final transactions =
        await getTransactions(accountId);

    double balance = 0;

    for (var t in transactions) {
      if (t.type == 'debit') {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }

    return balance;
  }

  Future<void> addTransaction(
    LedgerTransaction transaction,
  ) async {
    await _firebase.setDocument(
      'ledger_transactions',
      transaction.id,
      transaction.toMap(),
    );
  }

  Future<void> addLedgerEntry({
    required String accountId,
    required String accountType,
    required String type,
    required double amount,
    required String currency,
    required String orderId,
    required String note,
    required String companyId,
    required String pharmacyId,
  }) async {
    final transaction = LedgerTransaction(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      accountId: accountId,
      accountType: accountType,
      type: type,
      amount: amount,
      currency: currency,
      orderId: orderId,
      note: note,
      companyId: companyId,
      pharmacyId: pharmacyId,
      date: DateTime.now(),
    );

    await addTransaction(transaction);
  }
}