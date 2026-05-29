// lib/modules/company/screens/company_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/data/providers/order_provider.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/data/datasources/models/order_model.dart';
import 'package:app/data/providers/account_provider.dart';
import '../../../core/utils/order_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/snackbar_service.dart';
import 'edit_order_screen.dart';

class CompanyOrdersScreen extends StatefulWidget {
  const CompanyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<CompanyOrdersScreen> createState() => _CompanyOrdersScreenState();
}

class _CompanyOrdersScreenState extends State<CompanyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final companyId = auth.currentCompanyId ?? 'comp_001';
    final branchId = auth.getEffectiveBranchId();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    await orderProvider.loadOrdersForCompany(companyId, branchId: branchId);
  }

  Future<void> _refresh() async {
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('طلبات الشراء'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : orderProvider.orders.isEmpty
                    ? const Center(child: Text('لا توجد طلبات'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orderProvider.orders.length,
                        itemBuilder: (context, index) => CompanyOrderCard(
                          order: orderProvider.orders[index],
                          onStatusChanged: _refresh,
                        ),
                      ),
          ),
        );
      },
    );
  }
}

class CompanyOrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onStatusChanged;
  
  const CompanyOrderCard({Key? key, required this.order, required this.onStatusChanged}) : super(key: key);

  @override
  State<CompanyOrderCard> createState() => _CompanyOrderCardState();
}

class _CompanyOrderCardState extends State<CompanyOrderCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;
  final TextEditingController _rejectReasonController = TextEditingController();

  Future<void> _editOrder() async {
    if (_isProcessing) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditOrderScreen(order: widget.order),
      ),
    );
    
    if (result == true) {
      widget.onStatusChanged();
      SnackBarService.showSuccess('تم تعديل الطلب بنجاح');
    }
  }

  Future<void> _acceptOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      await orderProvider.acceptOrder(widget.order.id, accountProvider);
      widget.onStatusChanged();
      SnackBarService.showSuccess('تم قبول الطلب');
    } catch (e) {
      SnackBarService.showError('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.rejectOrder(widget.order.id, _rejectReasonController.text, null);
      widget.onStatusChanged();
      SnackBarService.showSuccess('تم رفض الطلب');
    } catch (e) {
      SnackBarService.showError('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateShipping() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(widget.order.id, 'shipped');
      widget.onStatusChanged();
      SnackBarService.showSuccess('تم تأكيد الشحن');
    } catch (e) {
      SnackBarService.showError('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateDelivered() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(widget.order.id, 'delivered');
      widget.onStatusChanged();
      SnackBarService.showSuccess('تم تسليم الطلب');
    } catch (e) {
      SnackBarService.showError('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    _rejectReasonController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى كتابة سبب الرفض:'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectReasonController, 
              decoration: const InputDecoration(
                hintText: 'مثال: المنتج غير متوفر',
                border: OutlineInputBorder(),
              ), 
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_rejectReasonController.text.isNotEmpty) {
                Navigator.pop(ctx);
                _rejectOrder();
              } else {
                SnackBarService.showWarning('يرجى كتابة سبب الرفض');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
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
                              '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}', 
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.pharmacyName, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'صيدلية: ${order.pharmacyName}', 
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              order.pharmacyCity, 
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: OrderHelper.getStatusColor(order.status).withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          OrderHelper.getStatusText(order.status), 
                          style: TextStyle(fontSize: 12, color: OrderHelper.getStatusColor(order.status)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50, 
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (ctx, idx) {
                      final item = order.items[idx];
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
                                    '${item.productName} (${item.quantity} ${item.unit == 'carton' ? 'كرتون' : 'باكيت'}) - ${item.quantityInPieces} باكيت', 
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
                  const SizedBox(height: 12),
                  
                  // أزرار التحكم حسب الصلاحيات وحالة الطلب
                  if (order.status == 'pending')
                    Row(
                      children: [
                        if (auth.canAcceptOrder || auth.canRejectOrder)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _editOrder,
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('تعديل'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
                                foregroundColor: Colors.orange,
                              ),
                            ),
                          ),
                        if (auth.canRejectOrder)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : _showRejectDialog,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: _isProcessing 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('رفض', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        if (auth.canRejectOrder && auth.canAcceptOrder) 
                          const SizedBox(width: 8),
                        if (auth.canAcceptOrder)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _acceptOrder,
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                              child: _isProcessing 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('قبول'),
                            ),
                          ),
                      ],
                    ),
                  if (order.status == 'accepted' && auth.canShipOrder)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _updateShipping,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        child: _isProcessing 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('تأكيد الشحن'),
                      ),
                    ),
                  if (order.status == 'shipped' && auth.canDeliverOrder)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _updateDelivered,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: _isProcessing 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('تسليم الطلب'),
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