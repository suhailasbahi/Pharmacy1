// lib/modules/reports/screens/tabs/advanced_report_tab.dart
import 'package:flutter/material.dart';
import 'package:app/core/extensions/num_extensions.dart';
import 'package:app/core/services/statistics_calculator.dart';
import 'package:app/core/services/sales_calculator.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/report_helper.dart';
import '../../../reports/widgets/line_chart_card.dart';
import '../../../reports/widgets/bar_chart_card.dart';
import '../../../reports/models/report_models.dart';
import '../../../reports/widgets/report_loading.dart';
import 'package:app/data/datasources/models/order_model.dart';

class AdvancedReportTab extends StatefulWidget {
  final List<OrderModel> orders;
  final TrendAnalysis? trendAnalysis;
  
  const AdvancedReportTab({
    Key? key,
    required this.orders,
    this.trendAnalysis,
  }) : super(key: key);

  @override
  State<AdvancedReportTab> createState() => _AdvancedReportTabState();
}

class _AdvancedReportTabState extends State<AdvancedReportTab> {
  late FunnelData _funnelData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateData();
  }

  void _calculateData() {
    int pending = 0, accepted = 0, shipped = 0, delivered = 0, rejected = 0;
    
    for (var order in widget.orders) {
      switch (order.status) {
        case 'pending': pending++; break;
        case 'accepted': accepted++; break;
        case 'shipped': shipped++; break;
        case 'delivered': delivered++; break;
        case 'rejected': rejected++; break;
      }
    }
    
    _funnelData = FunnelData(
      pending: pending,
      accepted: accepted,
      shipped: shipped,
      delivered: delivered,
      rejected: rejected,
    );
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ReportLoading(message: 'جاري تحليل البيانات...');
    }

    final monthlySales = ReportHelper.calculateMonthlySales(widget.orders);
    final monthlyData = ReportHelper.toChartData(monthlySales);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // تحليل الاتجاه
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تحليل الاتجاه',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTrendAnalysis(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // تحليل مسار التحويل (Funnel)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مسار تحويل الطلبات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFunnelChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // الإحصائيات المتقدمة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإحصائيات المتقدمة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAdvancedStats(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // توقعات المبيعات
          if (monthlyData.length >= 3)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'توقعات المبيعات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildForecast(monthlyData),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    if (widget.trendAnalysis == null) {
      return const Center(child: Text('لا توجد بيانات كافية للتحليل'));
    }
    
    final growthColor = widget.trendAnalysis!.isIncreasing 
        ? Colors.green 
        : (widget.trendAnalysis!.isDecreasing ? Colors.red : Colors.grey);
    final growthIcon = widget.trendAnalysis!.isIncreasing 
        ? Icons.trending_up 
        : (widget.trendAnalysis!.isDecreasing ? Icons.trending_down : Icons.trending_flat);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTrendItem(
              'اتجاه المبيعات',
              widget.trendAnalysis!.trend,
              growthIcon,
              growthColor,
            ),
            _buildTrendItem(
              'معدل النمو',
              '${widget.trendAnalysis!.growthRate.abs().toStringAsFixed(1)}%',
              widget.trendAnalysis!.isIncreasing ? Icons.arrow_upward : Icons.arrow_downward,
              growthColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: growthColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(growthIcon, color: growthColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.trendAnalysis!.isIncreasing
                      ? 'المبيعات في تحسن مستمر مقارنة بالفترة السابقة'
                      : (widget.trendAnalysis!.isDecreasing
                          ? 'المبيعات في انخفاض مقارنة بالفترة السابقة'
                          : 'المبيعات مستقرة مقارنة بالفترة السابقة'),
                  style: TextStyle(color: growthColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFunnelChart() {
    final maxValue = [_funnelData.pending, _funnelData.accepted, _funnelData.shipped, _funnelData.delivered]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    
    return Column(
      children: [
        _buildFunnelStage('قيد المراجعة', _funnelData.pending, maxValue, Colors.orange),
        const SizedBox(height: 8),
        _buildFunnelStage('تم القبول', _funnelData.accepted, maxValue, Colors.blue),
        const SizedBox(height: 8),
        _buildFunnelStage('تم الشحن', _funnelData.shipped, maxValue, Colors.purple),
        const SizedBox(height: 8),
        _buildFunnelStage('تم التسليم', _funnelData.delivered, maxValue, Colors.green),
        const SizedBox(height: 8),
        _buildFunnelStage('مرفوض', _funnelData.rejected, maxValue, Colors.red),
      ],
    );
  }

  Widget _buildFunnelStage(String label, int count, double maxValue, Color color) {
    final percentage = maxValue > 0 ? (count / maxValue) * 100 : 0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '$count طلب (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedStats() {
    final completedOrders = SalesCalculator.getCompletedOrders(widget.orders);
    final orderValues = completedOrders.map((o) => o.totalPrice).toList();
    final stdDev = StatisticsCalculator.calculateStdDev(orderValues);
    final median = StatisticsCalculator.calculateMedian(orderValues);
    
    return Column(
      children: [
        _buildStatRow('الانحراف المعياري', stdDev.formatCurrency(), Icons.show_chart),
        const Divider(),
        _buildStatRow('متوسط قيمة الطلب (وسيط)', median.formatCurrency(), Icons.analytics),
        const Divider(),
        _buildStatRow(
          'أعلى قيمة طلب',
          completedOrders.isEmpty ? '0' : orderValues.reduce((a, b) => a > b ? a : b).formatCurrency(),
          Icons.trending_up,
        ),
        const Divider(),
        _buildStatRow(
          'أقل قيمة طلب',
          completedOrders.isEmpty ? '0' : orderValues.reduce((a, b) => a < b ? a : b).formatCurrency(),
          Icons.trending_down,
        ),
      ],
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

  Widget _buildForecast(List<ChartDataPoint> monthlyData) {
    // توقع بسيط: متوسط آخر 3 أشهر
    final lastThree = monthlyData.reversed.take(3).toList();
    final forecast = lastThree.isEmpty 
        ? 0 
        : lastThree.fold(0.0, (sum, d) => sum + d.value) / lastThree.length;
    final nextMonth = monthlyData.isNotEmpty 
        ? _getNextMonth(monthlyData.last.label) 
        : 'الشهر القادم';
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'توقعات المبيعات',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                forecast.formatCurrency(),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                nextMonth,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '* بناءً على متوسط آخر 3 أشهر',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  String _getNextMonth(String currentLabel) {
    final parts = currentLabel.split('-');
    if (parts.length != 2) return 'الشهر القادم';
    
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
    
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    return '${monthNames[month - 1]} $year';
  }
}

class FunnelData {
  final int pending;
  final int accepted;
  final int shipped;
  final int delivered;
  final int rejected;
  
  FunnelData({
    required this.pending,
    required this.accepted,
    required this.shipped,
    required this.delivered,
    required this.rejected,
  });
  
  int get total => pending + accepted + shipped + delivered + rejected;
  double get conversionRate => total > 0 ? (delivered / total) * 100 : 0;
  double get rejectionRate => total > 0 ? (rejected / total) * 100 : 0;
}