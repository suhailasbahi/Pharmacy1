// lib/modules/company/screens/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/account_provider.dart';
import '../../../data/datasources/models/account_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/services/snackbar_service.dart';
import 'customer_statement_screen.dart';
import '../../payments/screens/add_payment_screen.dart';

class CustomersScreen extends StatefulWidget {
  final String companyId;

  const CustomersScreen({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<AccountProvider>(context, listen: false);
      await provider.loadCustomersForCompany(widget.companyId);
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isLoading) {
          return const Scaffold(
            appBar: AppBar(title: Text('حسابات العملاء'), centerTitle: true),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('حسابات العملاء'), centerTitle: true),
            body: ErrorWidget(
              message: provider.error!,
              onRetry: _loadCustomers,
            ),
          );
        }

        final customers = provider.getFilteredCustomers(_searchQuery);
        final totalBalance = provider.getTotalCustomersBalance(searchQuery: _searchQuery);

        if (customers.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('حسابات العملاء'),
              centerTitle: true,
              actions: [
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCustomers),
              ],
            ),
            body: const EmptyWidget(
              title: 'لا توجد حسابات عملاء',
              subtitle: 'سيظهر العملاء هنا بعد إتمام أول طلب',
              icon: Icons.people_outline,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('حسابات العملاء'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCustomers,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث عن عميل...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => _onSearchChanged(''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // ملخص الرصيد
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'إجمالي أرصدة العملاء',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${totalBalance.toStringAsFixed(0)} ر.ي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: totalBalance > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              
              // قائمة العملاء
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(customer, provider);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerCard(CustomerAccount customer, AccountProvider provider) {
    return FutureBuilder<double>(
      future: provider.getCustomerBalance(customer.id),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.pharmacyName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.phone.isEmpty ? 'بدون رقم' : customer.phone,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: balance > 0 ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('الرصيد', style: TextStyle(fontSize: 12)),
                          Text(
                            balance.toStringAsFixed(0),
                            style: TextStyle(
                              color: balance > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('كشف الحساب'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerStatementScreen(customer: customer),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payments, size: 18),
                        label: const Text('سداد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPaymentScreen(
                                accountId: customer.id,
                                accountType: 'customer',
                                companyId: customer.companyId,
                                pharmacyId: customer.pharmacyId,
                                accountName: customer.pharmacyName,
                                accountCurrency: customer.currency,
                              ),
                            ),
                          );
                          _loadCustomers();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}