// lib/modules/reports/screens/tabs/suppliers_report_tab.dart
import 'package:flutter/material.dart';
import 'package:app/core/extensions/num_extensions.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/services/debouncer.dart';
import 'package:app/data/datasources/models/order_model.dart';
import 'package:app/modules/reports/models/report_models.dart' as ReportModels;
import '../../widgets/bar_chart_card.dart';
import '../../widgets/report_table.dart';

class SuppliersReportTab extends StatefulWidget {
  final List<OrderModel> orders;
  final List<SupplierReport> topSuppliers;
  
  const SuppliersReportTab({
    Key? key,
    required this.orders,
    required this.topSuppliers,
  }) : super(key: key);

  @override
  State<SuppliersReportTab> createState() => _SuppliersReportTabState();
}

class _SuppliersReportTabState extends State<SuppliersReportTab> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer();
  String _searchQuery = '';
  List<SupplierReport> _filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    _filteredSuppliers = widget.topSuppliers;
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
    var suppliers = List<SupplierReport>.from(widget.topSuppliers);
    
    if (_searchQuery.isNotEmpty) {
      suppliers = suppliers.where((s) =>
        s.supplierName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    _filteredSuppliers = suppliers;
  }

  @override
  Widget build(BuildContext context) {
    final top5Suppliers = _filteredSuppliers.take(5).map((s) => BarChartDataPoint(
      label: s.supplierName.length > 15 ? '${s.supplierName.substring(0, 15)}...' : s.supplierName,
      value: s.totalPurchases,
    )).toList();
    
    final tableData = _filteredSuppliers.map((s) => [
      s.supplierName,
      s.totalPurchases.formatCurrency(),
      s.orderCount,
      s.averageOrderValue.formatCurrency(),
    ]).toList();
    
    final totalSuppliers = _filteredSuppliers.length;
    final totalPurchases = _filteredSuppliers.fold(0.0, (sum, s) => sum + s.totalPurchases);
    final averagePerSupplier = totalSuppliers > 0 ? totalPurchases / totalSuppliers : 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (top5Suppliers.isNotEmpty)
            BarChartCard(
              title: 'أفضل 5 موردين',
              data: top5Suppliers,
              color: AppTheme.primaryColor,
              unit: 'ر.ي',
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('إجمالي الموردين', '$totalSuppliers مورد', Icons.business),
                  const Divider(),
                  _buildStatRow('إجمالي المشتريات', '${totalPurchases.formatCurrency()} ر.ي', Icons.attach_money),
                  const Divider(),
                  _buildStatRow('متوسط المشتريات لكل مورد', '${averagePerSupplier.formatCurrency()} ر.ي', Icons.analytics),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث عن مورد...',
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('قائمة الموردين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ReportTable(
                    columns: ['المورد', 'إجمالي المشتريات', 'الطلبات', 'متوسط الطلب'],
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
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
      ],
    );
  }
}