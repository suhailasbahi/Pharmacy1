// lib/core/services/snackbar_service.dart
import 'package:flutter/material.dart';

class SnackBarService {
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  
  static void initialize(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }
  
  static GlobalKey<ScaffoldMessengerState>? get key => _scaffoldMessengerKey;
  
  /// عرض رسالة نجاح
  static void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    _showSnackBar(
      message: message,
      title: title ?? 'نجاح',
      color: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
    );
  }
  
  /// عرض رسالة خطأ
  static void showError(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? title,
  }) {
    _showSnackBar(
      message: message,
      title: title ?? 'خطأ',
      color: Colors.red,
      icon: Icons.error,
      duration: duration,
    );
  }
  
  /// عرض رسالة تحذير
  static void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    _showSnackBar(
      message: message,
      title: title ?? 'تنبيه',
      color: Colors.orange,
      icon: Icons.warning,
      duration: duration,
    );
  }
  
  /// عرض رسالة معلومات
  static void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 2),
    String? title,
  }) {
    _showSnackBar(
      message: message,
      title: title ?? 'معلومة',
      color: Colors.blue,
      icon: Icons.info,
      duration: duration,
    );
  }
  
  /// عرض رسالة مخصصة
  static void showCustom(
    String message, {
    required Color color,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    _showSnackBar(
      message: message,
      title: title,
      color: color,
      icon: icon,
      duration: duration,
    );
  }
  
  static void _showSnackBar({
    required String message,
    String? title,
    required Color color,
    IconData? icon,
    required Duration duration,
  }) {
    _scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(message)),
              ],
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  /// إغلاق جميع الـ SnackBars
  static void closeAll() {
    _scaffoldMessengerKey?.currentState?.clearSnackBars();
  }
  
  /// عرض SnackBar مع زر إجراء
  static void showAction({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color color = Colors.teal,
    Duration duration = const Duration(seconds: 5),
  }) {
    _scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
          textColor: Colors.white,
        ),
      ),
    );
  }
}