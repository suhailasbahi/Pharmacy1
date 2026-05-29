// lib/modules/reports/widgets/export_button.dart
import 'package:flutter/material.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback? onExportPDF;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportCSV;
  final VoidCallback? onExportImage;
  final bool showPDF;
  final bool showExcel;
  final bool showCSV;
  final bool showImage;
  final Color? color;
  
  const ExportButton({
    Key? key,
    this.onExportPDF,
    this.onExportExcel,
    this.onExportCSV,
    this.onExportImage,
    this.showPDF = true,
    this.showExcel = true,
    this.showCSV = true,
    this.showImage = true,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasOptions = (showPDF && onExportPDF != null) ||
                       (showExcel && onExportExcel != null) ||
                       (showCSV && onExportCSV != null) ||
                       (showImage && onExportImage != null);
    
    if (!hasOptions) return const SizedBox.shrink();
    
    // إذا كان هناك خيار واحد فقط، نعرض زر بسيط
    final singleOption = _getSingleOption();
    if (singleOption != null) {
      return IconButton(
        onPressed: singleOption.onPressed,
        icon: Icon(singleOption.icon, color: color ?? Colors.teal),
        tooltip: 'تصدير ${singleOption.format}',
      );
    }
    
    // إذا كان هناك عدة خيارات، نعرض زر مع قائمة منسدلة
    return PopupMenuButton<String>(
      icon: Icon(Icons.download, color: color ?? Colors.teal),
      tooltip: 'تصدير',
      onSelected: (value) => _onExportSelected(value),
      itemBuilder: (context) => [
        if (showPDF && onExportPDF != null)
          const PopupMenuItem(
            value: 'pdf',
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('PDF'),
              dense: true,
            ),
          ),
        if (showExcel && onExportExcel != null)
          const PopupMenuItem(
            value: 'excel',
            child: ListTile(
              leading: Icon(Icons.table_chart, color: Colors.green),
              title: Text('Excel'),
              dense: true,
            ),
          ),
        if (showCSV && onExportCSV != null)
          const PopupMenuItem(
            value: 'csv',
            child: ListTile(
              leading: Icon(Icons.grid_on, color: Colors.blue),
              title: Text('CSV'),
              dense: true,
            ),
          ),
        if (showImage && onExportImage != null)
          const PopupMenuItem(
            value: 'image',
            child: ListTile(
              leading: Icon(Icons.image, color: Colors.purple),
              title: Text('صورة'),
              dense: true,
            ),
          ),
      ],
    );
  }
  
  _ExportOption? _getSingleOption() {
    if (showPDF && onExportPDF != null && 
        !showExcel && !showCSV && !showImage) {
      return _ExportOption(
        format: 'PDF',
        icon: Icons.picture_as_pdf,
        onPressed: onExportPDF!,
      );
    }
    if (showExcel && onExportExcel != null && 
        !showPDF && !showCSV && !showImage) {
      return _ExportOption(
        format: 'Excel',
        icon: Icons.table_chart,
        onPressed: onExportExcel!,
      );
    }
    if (showCSV && onExportCSV != null && 
        !showPDF && !showExcel && !showImage) {
      return _ExportOption(
        format: 'CSV',
        icon: Icons.grid_on,
        onPressed: onExportCSV!,
      );
    }
    if (showImage && onExportImage != null && 
        !showPDF && !showExcel && !showCSV) {
      return _ExportOption(
        format: 'صورة',
        icon: Icons.image,
        onPressed: onExportImage!,
      );
    }
    return null;
  }
  
  void _onExportSelected(String value) {
    switch (value) {
      case 'pdf':
        onExportPDF?.call();
        break;
      case 'excel':
        onExportExcel?.call();
        break;
      case 'csv':
        onExportCSV?.call();
        break;
      case 'image':
        onExportImage?.call();
        break;
    }
  }
}

class _ExportOption {
  final String format;
  final IconData icon;
  final VoidCallback onPressed;
  
  _ExportOption({
    required this.format,
    required this.icon,
    required this.onPressed,
  });
}

/// زر تصدير مبسط مع تحميل تلقائي
class SimpleExportButton extends StatelessWidget {
  final VoidCallback onExport;
  final String label;
  final IconData? icon;
  final bool isLoading;
  
  const SimpleExportButton({
    Key? key,
    required this.onExport,
    this.label = 'تصدير',
    this.icon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onExport,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.download, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}