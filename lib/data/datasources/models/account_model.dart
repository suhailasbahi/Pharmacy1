import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAccount {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String phone;
  final double balance;
  final String currency;  // عملة الحساب (yemen, saudi, dollar)
  final DateTime createdAt;
  final String? branchId;
  final String companyId;

  CustomerAccount({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.phone,
    required this.balance,
    required this.currency,
    required this.createdAt,
    this.branchId,
    required this.companyId,
  });

  String get currencySymbol {
    switch (currency) {
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  factory CustomerAccount.fromMap(String id, Map<String, dynamic> map) {
    return CustomerAccount(
      id: id,
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'yemen',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      branchId: map['branchId'],
      companyId: map['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'phone': phone,
      'balance': balance,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'branchId': branchId,
      'companyId': companyId,
    };
  }

  CustomerAccount copyWith({
    String? id,
    String? pharmacyId,
    String? pharmacyName,
    String? phone,
    double? balance,
    String? currency,
    DateTime? createdAt,
    String? branchId,
    String? companyId,
  }) {
    return CustomerAccount(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      branchId: branchId ?? this.branchId,
      companyId: companyId ?? this.companyId,
    );
  }
}

class SupplierAccount {
  final String id;
  final String companyId;
  final String companyName;
  final String phone;
  final double balance;
  final String currency;  // عملة الحساب
  final DateTime createdAt;
  final String pharmacyId;

  SupplierAccount({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.phone,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.pharmacyId,
  });

  String get currencySymbol {
    switch (currency) {
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  factory SupplierAccount.fromMap(String id, Map<String, dynamic> map) {
    return SupplierAccount(
      id: id,
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'yemen',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      pharmacyId: map['pharmacyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'phone': phone,
      'balance': balance,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'pharmacyId': pharmacyId,
    };
  }

  SupplierAccount copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? phone,
    double? balance,
    String? currency,
    DateTime? createdAt,
    String? pharmacyId,
  }) {
    return SupplierAccount(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      pharmacyId: pharmacyId ?? this.pharmacyId,
    );
  }
}

// معاملة دفتر أستاذ
class LedgerTransaction {
  final String id;
  final String accountId;
  final String accountType;
  final String type;
  final double amount;
  final String currency;
  final String orderId;
  final String note;
  final String companyId;
  final String pharmacyId;
  final DateTime date;

  LedgerTransaction({
    required this.id,
    required this.accountId,
    required this.accountType,
    required this.type,
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.note,
    required this.companyId,
    required this.pharmacyId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'accountType': accountType,
      'type': type,
      'amount': amount,
      'currency': currency,
      'orderId': orderId,
      'note': note,
      'companyId': companyId,
      'pharmacyId': pharmacyId,
      'date': date.toIso8601String(),
    };
  }

  factory LedgerTransaction.fromMap(Map<String, dynamic> map) {
    return LedgerTransaction(
      id: map['id'] ?? '',
      accountId: map['accountId'] ?? '',
      accountType: map['accountType'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? '',
      orderId: map['orderId'] ?? '',
      note: map['note'] ?? '',
      companyId: map['companyId'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
    );
  }
}