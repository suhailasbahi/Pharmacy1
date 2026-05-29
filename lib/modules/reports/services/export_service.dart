// lib/modules/reports/services/export_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/snackbar_service.dart';

class ExportService {
  /// تصدير البيانات إلى CSV
  static Future<void> exportToCSV({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
    BuildContext? context,
  }) async {
    try {
      // بناء محتوى CSV
      final buffer = StringBuffer();
      
      // كتابة الرؤوس
      buffer.writeln(headers.join(','));
      
      // كتابة الصفوف
      for (var row in rows) {
        final escapedRow = row.map((cell) {
          String cellStr = cell.toString();
          if (cellStr.contains(',') || cellStr.contains('"')) {
            cellStr = '"${cellStr.replaceAll('"', '""')}"';
          }
          return cellStr;
        }).join(',');
        buffer.writeln(escapedRow);
      }
      
      // حفظ الملف
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      // مشاركة الملف
      await Share.shareXFiles([XFile(filePath)], text: 'تقرير $fileName');
      
      if (context != null) {
        SnackBarService.showSuccess('تم تصدير التقرير بنجاح');
      }
    } catch (e) {
      if (context != null) {
        SnackBarService.showError('حدث خطأ أثناء التصدير: $e');
      }
    }
  }
  
  /// تصدير البيانات إلى Excel (XLSX) - إصدار مبسط
  static Future<void> exportToExcel({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
    BuildContext? context,
  }) async {
    // يمكن استخدام حزمة excel أو نفس طريقة CSV
    await exportToCSV(
      headers: headers,
      rows: rows,
      fileName: fileName,
      context: context,
    );
  }
  
  /// تصدير إلى PDF (طلب من الخادم أو استخدام حزمة pdf)
  static Future<void> exportToPDF({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
    BuildContext? context,
  }) async {
    // للتصدير إلى PDF، يمكن استخدام حزمة printing أو pdf
    // حالياً نقوم بتصدير CSV كبديل
    await exportToCSV(
      headers: headers,
      rows: rows,
      fileName: fileName,
      context: context,
    );
  }
  
  /// تصدير البيانات كصورة (لقطة شاشة)
  static Future<void> exportToImage({
    required GlobalKey widgetKey,
    required String fileName,
    BuildContext? context,
  }) async {
    try {
      final boundary = widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;
      
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      await Share.shareXFiles([XFile(filePath)], text: 'تقرير $fileName');
      
      if (context != null) {
        SnackBarService.showSuccess('تم تصدير التقرير بنجاح');
      }
    } catch (e) {
      if (context != null) {
        SnackBarService.showError('حدث خطأ أثناء التصدير: $e');
      }
    }
  }
  
  /// تصدير بيانات المبيعات
  static Future<void> exportSalesReport({
    required List<dynamic> data,
    required String fileName,
    BuildContext? context,
  }) async {
    final headers = ['التاريخ', 'العميل', 'القيمة', 'الحالة', 'طريقة الدفع'];
    final rows = data.map((item) => [
      item['date'] ?? '',
      item['customer'] ?? '',
      item['amount'] ?? 0,
      item['status'] ?? '',
      item['paymentMethod'] ?? '',
    ]).toList();
    
    await exportToCSV(
      headers: headers,
      rows: rows,
      fileName: fileName,
      context: context,
    );
  }
  
  /// تصدير بيانات المنتجات
  static Future<void> exportProductsReport({
    required List<dynamic> data,
    required String fileName,
    BuildContext? context,
  }) async {
    final headers = ['المنتج', 'الكمية المباعة', 'الإيرادات', 'عدد الطلبات'];
    final rows = data.map((item) => [
      item['name'] ?? '',
      item['quantity'] ?? 0,
      item['revenue'] ?? 0,
      item['orders'] ?? 0,
    ]).toList();
    
    await exportToCSV(
      headers: headers,
      rows: rows,
      fileName: fileName,
      context: context,
    );
  }
}