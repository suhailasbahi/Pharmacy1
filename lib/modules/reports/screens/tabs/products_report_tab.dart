// lib/modules/reports/screens/tabs/products_report_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/extensions/num_extensions.dart';
import 'package:app/core/services/debouncer.dart';
import 'package:app/core/theme/app_theme.dart';
import '../../../../data/providers/report_provider.dart';
import '../../widgets/bar_chart_card.dart';
import '../../widgets/report_table.dart';
import '../../widgets/report_loading.dart';
import 'package:app/core/exports.dart';
import '../models/report_models.dart' as ReportModels;
import 'package:app/data/datasources/models/order_model.dart';

class ProductsReportTab extends StatefulWidget {
  final List<OrderModel> orders;
  
  const ProductsReportTab({
    Key? key,
    required this.orders,
  }) : super(key: key);

  @override
  State<ProductsReportTab> createState() => _ProductsReportTabState();
}

class _ProductsReportTabState extends State<ProductsReportTab> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer();
  late ReportProvider _reportProvider;

  @override
  void initState() {
    super.initState();
    _reportProvider = ReportProvider();
    _reportProvider.loadTopProducts(widget.orders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    _reportProvider.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.call(() {
      _reportProvider.setSearchQuery(query);
    });
  }

  void _changeSortOrder(String value) {
    _reportProvider.setSortBy(value);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _reportProvider,
      child: Consumer<ReportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const ReportLoading(message: 'جاري تحميل البيانات...');
          }

          final top5Data = provider.top5ProductsChartData;
          final tableData = provider.tableData;
          final totalQuantity = provider.totalQuantitySold;
          final totalRevenue = provider.totalRevenue;
          final uniqueProducts = provider.totalProducts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // أفضل 5 منتجات
                if (top5Data.isNotEmpty)
                  BarChartCard(
                    title: 'أفضل 5 منتجات مبيعاً',
                    data: top5Data,
                    color: Colors.teal,
                    unit: 'قطعة',
                  ),
                const SizedBox(height: 16),
                
                // إحصائيات سريعة
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'إجمالي المنتجات المباعة',
                          '${totalQuantity} قطعة',
                          Icons.inventory,
                        ),
                        const Divider(),
                        _buildStatRow(
                          'إجمالي الإيرادات',
                          '${totalRevenue.formatCurrency()} ر.ي',
                          Icons.attach_money,
                        ),
                        const Divider(),
                        _buildStatRow(
                          'عدد المنتجات الفريدة',
                          '$uniqueProducts منتج',
                          Icons.medication,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // فلتر البحث والترتيب
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'بحث عن منتج...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: provider.currentSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _reportProvider.clearFilters();
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('ترتيب حسب:'),
                            const SizedBox(width: 12),
                            _buildSortChip('الكمية', 'quantity', provider),
                            const SizedBox(width: 8),
                            _buildSortChip('الإيرادات', 'revenue', provider),
                            const SizedBox(width: 8),
                            _buildSortChip('عدد الطلبات', 'orders', provider),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // جدول المنتجات
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'قائمة المنتجات',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ReportTable(
                          columns: ['المنتج', 'الكمية', 'الإيرادات', 'الطلبات', 'متوسط السعر'],
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
        },
      ),
    );
  }

  Widget _buildSortChip(String label, String value, ReportProvider provider) {
    final isSelected = provider.currentSortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _changeSortOrder(value),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : null,
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