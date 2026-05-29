// lib/modules/reports/widgets/bar_chart_card.dart
// استبدل المحتوى بالكامل

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/extensions/num_extensions.dart';

class BarChartCard extends StatelessWidget {
  final String title;
  final List<BarChartDataPoint> data;
  final Color color;
  final double height;
  final String? unit;
  
  const BarChartCard({
    Key? key,
    required this.title,
    required this.data,
    this.color = Colors.teal,
    this.height = 250,
    this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bar_chart, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '($unit)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: height,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[index].label,
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: _leftTitleWidgets,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].value,
                          color: color,
                          width: 30,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: height + 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد بيانات كافية للعرض', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  static Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      value.formatNumber(),
      style: const TextStyle(fontSize: 11),
      textAlign: TextAlign.left,
    );
  }
}

class BarChartDataPoint {
  final String label;
  final double value;
  
  BarChartDataPoint({required this.label, required this.value});
}