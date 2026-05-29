class PaymentModel {
  final String id;
  final String accountId;
  final String accountType; // customer | supplier
  final String companyId;
  final String pharmacyId;
  
  // المبلغ الذي دفعه العميل فعلاً
  final double amountPaid;
  final String paidCurrency;  // yemen, saudi, dollar
  
  // المبلغ المحول إلى عملة الحساب (لخصم الرصيد)
  final double amountConverted;
  final String convertedCurrency;
  
  // سعر الصرف المستخدم
  final double? exchangeRate;
  
  final String paymentMethod; // cash | transfer | wallet
  final String note;
  final DateTime createdAt;
  final String? orderId;

  PaymentModel({
    required this.id,
    required this.accountId,
    required this.accountType,
    required this.companyId,
    required this.pharmacyId,
    required this.amountPaid,
    required this.paidCurrency,
    required this.amountConverted,
    required this.convertedCurrency,
    this.exchangeRate,
    required this.paymentMethod,
    required this.note,
    required this.createdAt,
    this.orderId,
  });

  String get paidCurrencySymbol {
    switch (paidCurrency) {
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  String get convertedCurrencySymbol {
    switch (convertedCurrency) {
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'accountType': accountType,
      'companyId': companyId,
      'pharmacyId': pharmacyId,
      'amountPaid': amountPaid,
      'paidCurrency': paidCurrency,
      'amountConverted': amountConverted,
      'convertedCurrency': convertedCurrency,
      'exchangeRate': exchangeRate,
      'paymentMethod': paymentMethod,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'orderId': orderId,
    };
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      accountId: map['accountId'] ?? '',
      accountType: map['accountType'] ?? '',
      companyId: map['companyId'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      paidCurrency: map['paidCurrency'] ?? 'yemen',
      amountConverted: (map['amountConverted'] ?? 0).toDouble(),
      convertedCurrency: map['convertedCurrency'] ?? 'yemen',
      exchangeRate: map['exchangeRate']?.toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      note: map['note'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      orderId: map['orderId'],
    );
  }
}