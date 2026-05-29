// lib/modules/pharmacy/screens/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/datasources/models/order_model.dart';
import '../../../core/utils/order_helper.dart';
import '../../../core/theme/app_theme.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final pharmacyId = auth.currentUserId ?? 'pharmacy_demo_123';
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    await orderProvider.loadOrdersForPharmacy(pharmacyId);
  }

  Future<void> _refresh() async {
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('طلباتي'),
              automaticallyImplyLeading: false,
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final orders = orderProvider.orders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('طلباتي'),
            automaticallyImplyLeading: false,
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('لا توجد طلبات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('قم بإتمام طلب من السلة', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) => OrderCard(order: orders[index]),
                  ),
          ),
        );
      },
    );
  }
}

// ✅ OrderCard محدث لاستخدام OrderHelper
class OrderCard extends StatefulWidget {
  final OrderModel order;
  const OrderCard({Key? key, required this.order}) : super(key: key);
  
  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.companyName, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'صيدلية: ${order.pharmacyName}', 
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'نوع الدفع: ${order.paymentTypeText} - ${order.paymentMethodText}', 
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: OrderHelper.getStatusColor(order.status).withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          OrderHelper.getStatusText(order.status), 
                          style: TextStyle(fontSize: 12, color: OrderHelper.getStatusColor(order.status)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التاريخ: ${OrderHelper.formatDate(order.date)}', 
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${OrderHelper.getTotalItems(order)} منتجات', 
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${order.totalPrice.toStringAsFixed(2)} ${order.currencySymbol}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.grey),
                      Text(
                        _isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل', 
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50, 
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} × ${item.quantity} ${item.unit == 'carton' ? 'كرتون' : 'باكيت'} (${item.quantityInPieces} باكيت)',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${item.totalPrice.toStringAsFixed(2)} ${order.currencySymbol}',
                                ),
                              ],
                            ),
                            if (item.bonusReceived != null && item.bonusReceived! > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, left: 8),
                                child: Text(
                                  '🎁 بونص: +${item.bonusReceived} حبة مجانية',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${order.totalPrice.toStringAsFixed(2)} ${order.currencySymbol}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  if (order.status == 'rejected' && order.rejectionReason != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('سبب الرفض:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 4),
                          Text(order.rejectionReason!),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}