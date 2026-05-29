// lib/modules/pharmacy/screens/supplier_statement_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/models/account_model.dart';
import '../../../data/providers/account_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/balance_calculator.dart';
import '../../payments/screens/add_payment_screen.dart';

class SupplierStatementScreen extends StatefulWidget {
  final SupplierAccount supplier;

  const SupplierStatementScreen({
    Key? key,
    required this.supplier,
  }) : super(key: key);

  @override
  State<SupplierStatementScreen> createState() => _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends State<SupplierStatementScreen> {
  List<RunningBalanceEntry> _transactions = [];
  Map<String, double> _summary = {};
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      
      var transactions = await accountProvider.getRunningBalance(widget.supplier.id);
      
      if (_startDate != null || _endDate != null) {
        transactions = transactions.where((t) {
          if (_startDate != null && t.date.isBefore(_startDate!)) return false;
          if (_endDate != null && t.date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
          return true;
        }).toList();
      }
      
      _transactions = transactions;
      
      final totalPurchases = _transactions.fold(0.0, (sum, t) => sum + t.debit);
      final totalPayments = _transactions.fold(0.0, (sum, t) => sum + t.credit);
      final double currentBalance = _transactions.isNotEmpty ? _transactions.last.balance : 0;
      
      _summary = {
        'totalPurchases': totalPurchases,
        'totalPayments': totalPayments,
        'currentBalance': currentBalance,
      };
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyDateFilter() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('كشف حساب ${widget.supplier.companyName}'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('كشف حساب ${widget.supplier.companyName}'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.payments),
        label: const Text('سداد'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPaymentScreen(
                accountId: widget.supplier.id,
                accountType: 'supplier',
                companyId: widget.supplier.companyId,
                pharmacyId: widget.supplier.pharmacyId,
                accountName: widget.supplier.companyName,
                accountCurrency: widget.supplier.currency,
              ),
            ),
          );
          _loadData();
        },
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                        _applyDateFilter();
                      }
                    },
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(_startDate == null ? 'من تاريخ' : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                        _applyDateFilter();
                      }
                    },
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(_endDate == null ? 'إلى تاريخ' : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _applyDateFilter();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCard('المشتريات', _summary['totalPurchases']?.toStringAsFixed(0) ?? '0', Colors.orange),
                _infoCard('المدفوعات', _summary['totalPayments']?.toStringAsFixed(0) ?? '0', Colors.green),
                _infoCard('الرصيد', _summary['currentBalance']?.toStringAsFixed(0) ?? '0', 
                  (_summary['currentBalance'] ?? 0) > 0 ? Colors.red : Colors.green),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('لا توجد معاملات'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
                      columns: const [
                        DataColumn(label: Text('التاريخ')),
                        DataColumn(label: Text('البيان')),
                        DataColumn(label: Text('مدين'), numeric: true),
                        DataColumn(label: Text('دائن'), numeric: true),
                        DataColumn(label: Text('الرصيد'), numeric: true),
                      ],
                      rows: _transactions.map((t) => DataRow(cells: [
                        DataCell(Text('${t.date.day}/${t.date.month}/${t.date.year}')),
                        DataCell(SizedBox(width: 200, child: Text(t.description))),
                        DataCell(Text(t.debit > 0 ? t.debit.toStringAsFixed(0) : '--', style: const TextStyle(color: Colors.red))),
                        DataCell(Text(t.credit > 0 ? t.credit.toStringAsFixed(0) : '--', style: const TextStyle(color: Colors.green))),
                        DataCell(Text(t.balance.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold))),
                      ])).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}