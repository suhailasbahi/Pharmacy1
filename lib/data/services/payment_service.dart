import 'package:cloud_firestore/cloud_firestore.dart';
import '../datasources/models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addPayment({required PaymentModel payment}) async {
    final batch = _firestore.batch();

    // 1. حفظ الدفعة
    final paymentRef = _firestore.collection('payments').doc(payment.id);
    batch.set(paymentRef, payment.toMap());

    // 2. إنشاء قيد محاسبي (بنفس عملة الحساب)
    final ledgerRef = _firestore.collection('ledger_transactions').doc();
    
    batch.set(ledgerRef, {
      'accountId': payment.accountId,
      'accountType': payment.accountType,
      'type': 'credit',
      'amount': payment.amountConverted,
      'currency': payment.convertedCurrency,
      'exchangeRate': payment.exchangeRate,
      'orderId': payment.orderId,
      'note': payment.note,
      'companyId': payment.companyId,
      'pharmacyId': payment.pharmacyId,
      'paymentMethod': payment.paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. تنفيذ العملية
    await batch.commit();
  }
}