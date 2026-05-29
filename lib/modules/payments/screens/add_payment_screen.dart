// lib/modules/payments/screens/add_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../data/datasources/models/payment_model.dart';
import '../../../data/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/currency_converter.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/constants/app_constants.dart';

class AddPaymentScreen extends StatefulWidget {
  final String accountId;
  final String accountType;
  final String companyId;
  final String pharmacyId;
  final String accountName;
  final String accountCurrency;

  const AddPaymentScreen({
    Key? key,
    required this.accountId,
    required this.accountType,
    required this.companyId,
    required this.pharmacyId,
    required this.accountName,
    required this.accountCurrency,
  }) : super(key: key);

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isSaving = false;
  String _paymentMethod = 'cash';
  String _paymentCurrency = AppConstants.currencyYer;
  double _convertedAmount = 0;
  double _exchangeRate = 1.0;

  final PaymentService _paymentService = PaymentService();

  void _updateConversion() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0) {
      setState(() {
        _convertedAmount = 0;
        _exchangeRate = 1.0;
      });
      return;
    }
    
    // ✅ استخدام CurrencyConverter Service
    _convertedAmount = CurrencyConverter.convertAndRound(
      amount: amount,
      fromCurrency: _paymentCurrency,
      toCurrency: widget.accountCurrency,
    );
    
    _exchangeRate = CurrencyConverter.getExchangeRate(
      fromCurrency: _paymentCurrency,
      toCurrency: widget.accountCurrency,
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final exchangeRate = _paymentCurrency != widget.accountCurrency ? _exchangeRate : null;

      final payment = PaymentModel(
        id: const Uuid().v4(),
        accountId: widget.accountId,
        accountType: widget.accountType,
        companyId: widget.companyId,
        pharmacyId: widget.pharmacyId,
        amountPaid: amount,
        paidCurrency: _paymentCurrency,
        amountConverted: _convertedAmount,
        convertedCurrency: widget.accountCurrency,
        exchangeRate: exchangeRate,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty ? 'دفعة سداد' : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _paymentService.addPayment(payment: payment);

      if (!mounted) return;
      
      SnackBarService.showSuccess('تم تسجيل الدفعة بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDifferentCurrency = _paymentCurrency != widget.accountCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة دفعة'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.accountName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'الحساب مقوم بـ ${CurrencyConverter.getSymbol(widget.accountCurrency)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Currency
            const Text('عملة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AppConstants.currencyYer,
                  label: Text('ريال يمني'),
                  icon: Icon(Icons.money, size: 18),
                ),
                ButtonSegment(
                  value: AppConstants.currencySar,
                  label: Text('ريال سعودي'),
                  icon: Icon(Icons.swap_horiz, size: 18),
                ),
                ButtonSegment(
                  value: AppConstants.currencyUsd,
                  label: Text('دولار'),
                  icon: Icon(Icons.attach_money, size: 18),
                ),
              ],
              selected: {_paymentCurrency},
              onSelectionChanged: (set) {
                setState(() {
                  _paymentCurrency = set.first;
                  _updateConversion();
                });
              },
            ),
            const SizedBox(height: 20),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ (${CurrencyConverter.getSymbol(_paymentCurrency)})',
                prefixIcon: const Icon(Icons.money),
              ),
              onChanged: (_) => _updateConversion(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'أدخل المبلغ';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) return 'مبلغ غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'طريقة الدفع',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                DropdownMenuItem(value: 'transfer', child: Text('حوالة')),
                DropdownMenuItem(value: 'wallet', child: Text('محفظة إلكترونية')),
              ],
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            const SizedBox(height: 20),

            // Note
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            // Conversion Result
            if (isDifferentCurrency) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سيتم خصم:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          CurrencyConverter.formatAmount(
                            amount: _convertedAmount,
                            currency: widget.accountCurrency,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سعر الصرف:', style: TextStyle(fontSize: 12)),
                        Text(
                          CurrencyConverter.formatConversion(
                            amount: 1,
                            fromCurrency: _paymentCurrency,
                            toCurrency: widget.accountCurrency,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePayment,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ الدفعة'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}