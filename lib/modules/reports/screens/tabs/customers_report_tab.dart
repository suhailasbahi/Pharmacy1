// lib/modules/reports/screens/tabs/customers_report_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/extensions/num_extensions.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/services/debouncer.dart';
import 'package:app/data/providers/report_provider.dart';
import 'package:app/modules/reports/models/report_models.dart' as ReportModels;
import '../../widgets/bar_chart_card.dart';
import '../../widgets/report_table.dart';
import 'package:app/core/exports.dart';
import 'package:app/data/datasources/models/order_model.dart';

class CustomersReportTab extends StatefulWidget {
  final List<OrderModel> orders;
  final List<CustomerReport> topCustomers;
  
  const CustomersReportTab({
    Key? key,
    required this.orders,
    required this.topCustomers,
  }) : super(key: key);

  @override
  State<CustomersReportTab> createState() => _CustomersReportTabState();
}

class _CustomersReportTabState extends State<CustomersReportTab> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer();
  String _searchQuery = '';
  List<CustomerReport> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.topCustomers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.call(() {
      setState(() {
        _searchQuery = query;
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    var customers = List<CustomerReport>.from(widget.topCustomers);
    
    if (_searchQuery.isNotEmpty) {
      customers = customers.where((c) =>
        c.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.customerCity.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    _filteredCustomers = customers;
  }

  @override
  Widget build(BuildContext context) {
    final top5Customers = _filteredCustomers.take(5).map((c) => ReportModels.ChartData(
      label: c.customerName.length > 15 ? '${c.customerName.substring(0, 15)}...' : c.customerName,
      value: c.totalPurchases,
    )).toList();
    
    final tableData = _filteredCustomers.map((c) => [
      c.customerName,
      c.customerCity,
      c.totalPurchases.formatCurrency(),
      c.orderCount,
      c.averageOrderValue.formatCurrency(),
      '${c.cashPercentage.toStringAsFixed(1)}% / ${c.creditPercentage.toStringAsFixed(1)}%',
    ]).toList();
    
    // ✅ إحصائيات إضافية محسوبة
    final totalCustomers = _filteredCustomers.length;
    final totalPurchases = _filteredCustomers.fold(0.0, (sum, c) => sum + c.totalPurchases);
    final averagePerCustomer = totalCustomers > 0 ? totalPurchases / totalCustomers : 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // أفضل 5 عملاء
          if (top5Customers.isNotEmpty)
            BarChartCard(
              title: 'أفضل 5 عملاء',
              data: top5Customers,
              color: AppTheme.primaryColor,
              unit: 'ر.ي',
            ),
          const SizedBox(height: 16),
          
          // إحصائيات سريعة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow(
                    'إجمالي العملاء',
                    '$totalCustomers عميل',
                    Icons.people,
                  ),
                  const Divider(),
                  _buildStatRow(
                    'إجمالي المشتريات',
                    '${totalPurchases.formatCurrency()} ر.ي',
                    Icons.attach_money,
                  ),
                  const Divider(),
                  _buildStatRow(
                    'متوسط المشتريات لكل عميل',
                    '${averagePerCustomer.formatCurrency()} ر.ي',
                    Icons.analytics,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // بحث
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث عن عميل...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // جدول العملاء
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'قائمة العملاء',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ReportTable(
                    columns: ['العميل', 'المدينة', 'إجمالي المشتريات', 'الطلبات', 'متوسط الطلب', 'نقدي/آجل'],
                    rows: tableData,
                    isStriped: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
      ],
    );
  }
}