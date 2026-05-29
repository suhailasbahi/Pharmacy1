// lib/modules/reports/screens/tabs/sales_report_tab.dart
import 'package:flutter/material.dart';
import 'package:app/core/extensions/num_extensions.dart';
import 'package:app/core/utils/report_helper.dart';
import 'package:app/core/theme/app_theme.dart';
import '../../models/report_models.dart'as ReportModels;
import '../../widgets/line_chart_card.dart';
import '../../widgets/pie_chart_card.dart';
import '../../widgets/bar_chart_card.dart';
import '../../widgets/report_table.dart';
import 'package:app/core/exports.dart';
import 'package:app/data/datasources/models/order_model.dart';

class SalesReportTab extends StatelessWidget {
  final List<OrderModel> orders;
  final SalesSummary? salesSummary;
  
  const SalesReportTab({
    Key? key,
    required this.orders,
    this.salesSummary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ استخدام ReportHelper للحسابات
    final monthlySales = ReportHelper.calculateMonthlySales(orders);
    final monthlyData = ReportHelper.toChartData(monthlySales);
    
    final dailySales = ReportHelper.calculateDailySales(orders);
    final dailyData = ReportHelper.toChartData(dailySales);
    
    final paymentData = ReportHelper.calculatePaymentDistribution(orders);
    final paymentChartData = [
      PieChartDataPoint(label: 'نقدي', value: paymentData['cash'] ?? 0),
      PieChartDataPoint(label: 'آجل', value: paymentData['credit'] ?? 0),
    ];
    
    final tableData = ReportHelper.getRecentOrdersTableData(orders);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // اتجاه المبيعات الشهري
          if (monthlyData.isNotEmpty)
            LineChartCard(
              title: 'اتجاه المبيعات الشهري',
              data: monthlyData,
              color: AppTheme.primaryColor,
              unit: 'ر.ي',
            ),
          const SizedBox(height: 16),
          
          // المبيعات اليومية (آخر 30 يوم)
          if (dailyData.isNotEmpty)
            BarChartCard(
              title: 'المبيعات اليومية (آخر 30 يوم)',
              data: dailyData,
              color: Colors.blue,
              unit: 'ر.ي',
            ),
          const SizedBox(height: 16),
          
          // توزيع المبيعات حسب طريقة الدفع
          PieChartCard(
            title: 'توزيع المبيعات حسب طريقة الدفع',
            data: paymentChartData,
          ),
          const SizedBox(height: 16),
          
          // آخر الطلبات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'آخر الطلبات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ReportTable(
                    columns: ['التاريخ', 'العميل', 'المنتجات', 'الإجمالي', 'الدفع', 'الحالة'],
                    rows: tableData,
                    isStriped: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}