// lib/modules/reports/widgets/pie_chart_card.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/extensions/num_extensions.dart';

class PieChartCard extends StatelessWidget {
  final String title;
  final List<PieChartDataPoint> data;
  final double height;
  final List<Color>? colors;
  
  const PieChartCard({
    Key? key,
    required this.title,
    required this.data,
    this.height = 280,
    this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColors = [Colors.green, Colors.orange, Colors.blue, Colors.red, Colors.purple, Colors.teal];
    final chartColors = colors ?? defaultColors;
    final total = data.fold(0.0, (sum, d) => sum + d.value);
    
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
            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pie_chart, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (data.isEmpty)
              SizedBox(
                height: height - 70,
                child: const Center(
                  child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: height,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(data.length, (i) {
                          final percentage = total > 0 ? (data[i].value / total) * 100 : 0;
                          return PieChartSectionData(
                            value: data[i].value,
                            title: '${percentage.toStringAsFixed(1)}%',
                            color: chartColors[i % chartColors.length],
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(data.length, (i) {
                      final percentage = total > 0 ? (data[i].value / total) * 100 : 0;
                      return _buildLegendItem(
                        data[i].label,
                        '${data[i].value.formatNumber()} (${percentage.toStringAsFixed(1)}%)',
                        chartColors[i % chartColors.length],
                      );
                    }),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class PieChartDataPoint {
  final String label;
  final double value;
  
  PieChartDataPoint({
    required this.label,
    required this.value,
  });
}