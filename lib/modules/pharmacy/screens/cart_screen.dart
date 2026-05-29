// lib/modules/pharmacy/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/services/bonus_calculator.dart';
import '../../../core/services/cart_calculator.dart';
import '../../../core/services/currency_converter.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/widgets/quantity_selector.dart';
import '../../../core/utils/category_utils.dart';
import '../../../data/datasources/models/cart_item.dart';
import '../../../data/datasources/models/order_model.dart';
import 'pharmacy_home.dart';

class CartScreen extends StatefulWidget {
  final bool isGuest;
  const CartScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, Map<String, dynamic>> _paymentOptions = {};

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, AuthService>(
      builder: (context, cartProvider, authService, child) {
        if (cartProvider.items.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('سلة المشتريات'),
              centerTitle: true,
            ),
            body: const EmptyCartWidget(),
          );
        }

        // ✅ استخدام دوال Provider بدلاً من الحساب المباشر
        final itemsByCompany = cartProvider.itemsByCompanyAndCurrency;
        final totalText = cartProvider.getTotalText();

        // تهيئة خيارات الدفع لكل مجموعة
        for (var key in itemsByCompany.keys) {
          if (!_paymentOptions.containsKey(key)) {
            _paymentOptions[key] = {
              'paymentType': 'cash',
              'paymentMethod': 'transfer',
              'creditDays': null,
            };
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('سلة المشتريات (${cartProvider.totalQuantity})'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _confirmClearCart(cartProvider),
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 180),
                itemCount: itemsByCompany.keys.length,
                itemBuilder: (context, index) {
                  final key = itemsByCompany.keys.toList()[index];
                  final companyItems = itemsByCompany[key]!;
                  // ✅ استخدام دالة Provider
                  final companyTotal = cartProvider.getCompanyTotal(
                    companyItems.first.companyId,
                    companyItems.first.currency,
                  );
                  final paymentOpt = _paymentOptions[key]!;
                  final isCash = paymentOpt['paymentType'] == 'cash';
                  final currency = companyItems.first.currency;
                  final currencySymbol = CurrencyConverter.getSymbol(currency);
                  final companyName = companyItems.first.companyName;

                  return Card(
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$companyName ($currencySymbol)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${companyTotal.toStringAsFixed(2)} $currencySymbol',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ...companyItems.map((item) => _buildCartItem(item, cartProvider, isCash)),
                        _buildPaymentOptions(key, paymentOpt, cartProvider),
                      ],
                    ),
                  );
                },
              ),
              _buildCheckoutButton(itemsByCompany, cartProvider, authService, totalText),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider, bool isCash) {
    final category = CategoryUtils.getCategoryFromName(item.name);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category.icon, color: category.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${item.unitPrice} ${item.currencySymbol}', style: TextStyle(color: AppTheme.primaryColor)),
                      if (item.requiresCooling)
                        const Text('يحتاج تبريد', style: TextStyle(fontSize: 10, color: Colors.blue)),
                      if (item.bonus > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🎁 بونص: +${item.bonus} حبة مجانية',
                            style: TextStyle(fontSize: 10, color: Colors.green.shade800),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('الوحدة:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: item.unit,
                  items: const [
                    DropdownMenuItem(value: 'piece', child: Text('باكيت')),
                    DropdownMenuItem(value: 'carton', child: Text('كرتون')),
                  ],
                  onChanged: (newUnit) {
                    if (newUnit != null && newUnit != item.unit) {
                      cartProvider.changeUnit(item.id, newUnit, context, isCashOrder: isCash);
                    }
                  },
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
                const Spacer(),
                QuantitySelector(
                  initialQuantity: item.quantity,
                  minQuantity: CartCalculator.getMinAllowedQuantity(item),
                  maxQuantity: 999,
                  onQuantityChanged: (qty) {
                    cartProvider.updateQuantity(item.id, qty, isCashOrder: isCash);
                  },
                  buttonSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => cartProvider.removeItem(item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptions(String key, Map<String, dynamic> paymentOpt, CartProvider cartProvider) {
    return Container(
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
          const Divider(),
          const Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: RadioListTile(
                  title: const Text('نقدي'),
                  value: 'cash',
                  groupValue: paymentOpt['paymentType'],
                  onChanged: (value) {
                    setState(() {
                      _paymentOptions[key]!['paymentType'] = value;
                    });
                    cartProvider.updateBonusesForCompany(key.split('_')[0], value == 'cash');
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile(
                  title: const Text('أجل'),
                  value: 'credit',
                  groupValue: paymentOpt['paymentType'],
                  onChanged: (value) {
                    setState(() {
                      _paymentOptions[key]!['paymentType'] = value;
                    });
                    cartProvider.updateBonusesForCompany(key.split('_')[0], value == 'cash');
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (paymentOpt['paymentType'] == 'credit')
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد أيام الأجل',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _paymentOptions[key]!['creditDays'] = int.tryParse(value),
            ),
          if (paymentOpt['paymentType'] == 'cash') ...[
            const Text('وسيلة الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('حوالة'),
                  selected: paymentOpt['paymentMethod'] == 'transfer',
                  onSelected: (selected) => setState(() {
                    _paymentOptions[key]!['paymentMethod'] = selected ? 'transfer' : '';
                  }),
                ),
                ChoiceChip(
                  label: const Text('محفظة إلكترونية'),
                  selected: paymentOpt['paymentMethod'] == 'wallet',
                  onSelected: (selected) => setState(() {
                    _paymentOptions[key]!['paymentMethod'] = selected ? 'wallet' : '';
                  }),
                ),
                ChoiceChip(
                  label: const Text('كاش عند الاستلام'),
                  selected: paymentOpt['paymentMethod'] == 'cash_on_delivery',
                  onSelected: (selected) => setState(() {
                    _paymentOptions[key]!['paymentMethod'] = selected ? 'cash_on_delivery' : '';
                  }),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(
    Map<String, List<CartItem>> itemsByGroup,
    CartProvider cartProvider,
    AuthService authService,
    String totalText,
  ) {
    final pharmacyId = authService.currentUserId ?? 'pharmacy_demo_123';
    final pharmacyName = authService.currentPharmacyName ?? 'صيدلية تجريبية';
    final pharmacyCity = authService.currentRegionId ?? 'صنعاء';
    final regionId = authService.currentRegionId ?? 'sanaa';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي الكلي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    totalText,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _checkout(itemsByGroup, cartProvider, authService, pharmacyId, pharmacyName, pharmacyCity, regionId),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('إتمام الطلبات', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(
    Map<String, List<CartItem>> itemsByGroup,
    CartProvider cartProvider,
    AuthService authService,
    String pharmacyId,
    String pharmacyName,
    String pharmacyCity,
    String regionId,
  ) async {
    // تأكيد الطلب
    final confirmed = await _showCheckoutConfirmation(itemsByGroup, cartProvider);
    if (!confirmed) return;

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      for (var entry in itemsByGroup.entries) {
        final items = entry.value;
        final paymentOpt = _paymentOptions[entry.key]!;
        final groupTotalPrice = cartProvider.getCompanyTotal(
          items.first.companyId,
          items.first.currency,
        );

        final orderItems = items.map((cartItem) => OrderItem(
          productId: cartItem.id,
          productName: cartItem.name,
          scientificName: cartItem.scientificName,
          quantity: cartItem.quantity,
          quantityInPieces: cartItem.totalPieces,
          unit: cartItem.unit,
          piecesPerCarton: cartItem.piecesPerCarton,
          price: cartItem.unitPrice,
          bonusReceived: cartItem.bonus,
          totalPrice: cartItem.totalPrice,
        )).toList();

        final order = OrderModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
          items: orderItems,
          totalPrice: groupTotalPrice,
          companyId: items.first.companyId,
          companyName: items.first.companyName,
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyName,
          pharmacyCity: pharmacyCity,
          regionId: regionId,
          status: 'pending',
          currency: items.first.currency,
          date: DateTime.now(),
          paymentType: paymentOpt['paymentType'],
          paymentMethod: paymentOpt['paymentType'] == 'cash' ? paymentOpt['paymentMethod'] : '',
          creditDays: paymentOpt['paymentType'] == 'credit' ? paymentOpt['creditDays'] : null,
        );

        await orderProvider.createOrder(order);
      }

      cartProvider.clearCart();
      _paymentOptions.clear();
      
      SnackBarService.showSuccess('تم إرسال الطلبات بنجاح');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => PharmacyHomeScreen(selectedCity: pharmacyCity, isGuest: widget.isGuest)),
          (route) => false,
        );
      }
    } catch (e) {
      SnackBarService.showError('حدث خطأ: ${e.toString()}');
    }
  }

  Future<bool> _showCheckoutConfirmation(Map<String, List<CartItem>> itemsByGroup, CartProvider cartProvider) async {
    final totalItems = cartProvider.totalQuantity;
    final totalPrice = cartProvider.totalPrice;
    final companiesCount = itemsByGroup.length;
    
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('عدد المنتجات: $totalItems'),
            Text('عدد الشركات: $companiesCount'),
            Text('الإجمالي: ${totalPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text('هل أنت متأكد من إتمام الطلب؟', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _confirmClearCart(CartProvider cartProvider) async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفريغ السلة'),
        content: const Text('هل أنت متأكد من تفريغ السلة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تفريغ'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      cartProvider.clearCart();
      SnackBarService.showSuccess('تم تفريغ السلة');
    }
  }
}