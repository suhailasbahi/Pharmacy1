// lib/modules/reports/screens/tabs/regions_report_tab.dart
import 'package:flutter/material.dart';
import 'package:app/core/extensions/num_extensions.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/report_helper.dart';
import 'package:app/modules/reports/models/report_models.dart' as ReportModels;
import '../../widgets/bar_chart_card.dart';
import '../../widgets/report_table.dart';
import 'package:app/data/datasources/models/order_model.dart';

class RegionsReportTab extends StatelessWidget {
  final List<OrderModel> orders;
  final List<RegionReport> topRegions;
  
  const RegionsReportTab({
    Key? key,
    required this.orders,
    required this.topRegions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final regionData = topRegions.map((r) => ReportModels.ChartData(
      label: r.regionName.length > 10 ? r.regionName.substring(0, 10) : r.regionName,
      value: r.sales,
    )).toList();
    
    final tableData = topRegions.map((r) => [
      r.regionName,
      r.sales.formatCurrency(),
      r.orderCount,
      r.customerCount,
      r.averageOrderValue.formatCurrency(),
      '${r.percentageOfTotal.toStringAsFixed(1)}%',
    ]).toList();
    
    // ✅ إحصائيات محسوبة
    final totalRegions = topRegions.length;
    final totalSales = topRegions.fold(0.0, (sum, r) => sum + r.sales);
    final topRegion = topRegions.isNotEmpty ? topRegions.first : null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // توزيع المبيعات حسب المناطق
          if (regionData.isNotEmpty)
            BarChartCard(
              title: 'المبيعات حسب المناطق',
              data: regionData,
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
                    'عدد المناطق النشطة',
                    '$totalRegions منطقة',
                    Icons.location_on,
                  ),
                  const Divider(),
                  _buildStatRow(
                    'إجمالي المبيعات',
                    '${totalSales.formatCurrency()} ر.ي',
                    Icons.attach_money,
                  ),
                  if (topRegion != null) ...[
                    const Divider(),
                    _buildStatRow(
                      'أفضل منطقة',
                      '${topRegion.regionName} (${topRegion.sales.formatCurrency()})',
                      Icons.emoji_events,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // خريطة نصية للمناطق
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'توزيع المبيعات الجغرافي',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildRegionMap(topRegions, totalSales),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // جدول المناطق
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفاصيل المناطق',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ReportTable(
                    columns: ['المنطقة', 'المبيعات', 'الطلبات', 'العملاء', 'متوسط الطلب', 'النسبة'],
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

  Widget _buildRegionMap(List<dynamic> regions, double totalSales) {
    return Column(
      children: regions.map((region) {
        final percentage = totalSales > 0 ? (region.sales / totalSales) * 100 : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    region.regionName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}% (${region.sales.formatCurrency()})',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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