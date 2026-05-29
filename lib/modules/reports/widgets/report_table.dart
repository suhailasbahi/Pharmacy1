// lib/modules/reports/widgets/report_table.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/num_extensions.dart';

class ReportTable extends StatelessWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool showHeader;
  final double columnSpacing;
  final bool hasBorder;
  final bool isStriped;
  final Color? headerColor;
  final Color? rowColor;
  final Color? alternateRowColor;
  final Function(int rowIndex)? onRowTap;
  final String? emptyMessage;
  
  const ReportTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.showHeader = true,
    this.columnSpacing = 20,
    this.hasBorder = true,
    this.isStriped = true,
    this.headerColor,
    this.rowColor,
    this.alternateRowColor,
    this.onRowTap,
    this.emptyMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: columnSpacing,
        headingRowColor: showHeader ? MaterialStateProperty.all(headerColor ?? AppTheme.primaryColor.withOpacity(0.1)) : null,
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (!isStriped) return rowColor ?? Colors.transparent;
          return null; // سيتم التعامل معه في DataRow
        }),
        border: hasBorder ? TableBorder.all(color: Colors.grey.shade300, width: 0.5) : null,
        columns: columns.map((col) => DataColumn(
          label: Text(
            col,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: headerColor != null ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        )).toList(),
        rows: List.generate(rows.length, (index) {
          final row = rows[index];
          return DataRow(
            color: isStriped && index % 2 == 1
                ? MaterialStateProperty.all(alternateRowColor ?? Colors.grey.shade50)
                : MaterialStateProperty.all(rowColor ?? Colors.transparent),
            onSelectChanged: onRowTap != null ? (_) => onRowTap!(index) : null,
            cells: List.generate(row.length, (colIndex) {
              final value = row[colIndex];
              return DataCell(
                _buildCell(value, colIndex),
                onTap: onRowTap != null ? () => onRowTap!(index) : null,
              );
            }),
          );
        }),
      ),
    );
  }
  
  Widget _buildCell(dynamic value, int colIndex) {
    if (value == null || value.toString().isEmpty) {
      return const Text('--', style: TextStyle(color: Colors.grey));
    }
    
    if (value is double || value is int || value is num) {
      final number = value.toDouble();
      final isMoney = colIndex > 0; // نفترض أن الأعمدة الأولى اسم، والباقي أرقام
      return Text(
        isMoney ? number.formatCurrency() : number.toString(),
        style: TextStyle(
          color: number < 0 ? Colors.red : (colIndex == 0 ? AppTheme.textPrimary : Colors.teal),
          fontWeight: colIndex == 0 ? FontWeight.normal : FontWeight.w500,
        ),
      );
    }
    
    if (value is DateTime) {
      return Text(
        '${value.day}/${value.month}/${value.year}',
        style: const TextStyle(fontSize: 12),
      );
    }
    
    return Text(
      value.toString(),
      style: const TextStyle(fontSize: 13),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.inbox, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              emptyMessage ?? 'لا توجد بيانات',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// نسخة مبسطة للجدول (بدون DataTable، يستخدم ListView)
class SimpleReportTable extends StatelessWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final Function(int rowIndex)? onRowTap;
  
  const SimpleReportTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.onRowTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: columns.map((col) => Expanded(
              child: Text(
                col,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )).toList(),
          ),
        ),
        
        // Rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final isEven = index % 2 == 0;
            
            return InkWell(
              onTap: onRowTap != null ? () => onRowTap!(index) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: List.generate(row.length, (colIndex) {
                    final value = row[colIndex];
                    return Expanded(
                      child: Text(
                        _formatValue(value),
                        style: TextStyle(
                          color: colIndex == 0 ? AppTheme.textPrimary : Colors.teal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  String _formatValue(dynamic value) {
    if (value == null) return '--';
    if (value is double) return value.formatCurrency();
    if (value is DateTime) return '${value.day}/${value.month}/${value.year}';
    return value.toString();
  }
}