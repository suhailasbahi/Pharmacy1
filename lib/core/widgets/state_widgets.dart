// lib/core/widgets/state_widgets.dart
import 'package:flutter/material.dart';

/// شاشة التحميل
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Widget? child;
  
  const LoadingWidget({Key? key, this.message, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child ?? const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

/// شاشة الخطأ
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? buttonText;
  
  const ErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
    this.buttonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[300]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(buttonText ?? 'إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

/// شاشة فارغة (لا توجد بيانات)
class EmptyWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const EmptyWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// شاشة فارغة للسلة
class EmptyCartWidget extends StatelessWidget {
  final VoidCallback? onBrowse;
  
  const EmptyCartWidget({Key? key, this.onBrowse}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyWidget(
      title: 'السلة فارغة',
      subtitle: 'أضف منتجات إلى السلة من خلال التصفح',
      icon: Icons.shopping_cart_outlined,
      onAction: onBrowse,
      actionLabel: 'تصفح المنتجات',
    );
  }
}

/// شاشة فارغة للطلبات
class EmptyOrdersWidget extends StatelessWidget {
  final VoidCallback? onShop;
  
  const EmptyOrdersWidget({Key? key, this.onShop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyWidget(
      title: 'لا توجد طلبات',
      subtitle: 'قم بإتمام طلب من السلة',
      icon: Icons.shopping_bag_outlined,
      onAction: onShop,
      actionLabel: 'تسوق الآن',
    );
  }
}