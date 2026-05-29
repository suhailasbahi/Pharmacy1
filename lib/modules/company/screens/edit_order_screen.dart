// lib/modules/company/screens/edit_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/data/providers/order_provider.dart';
import 'package:app/data/providers/product_provider.dart';
import 'package:app/data/datasources/models/order_model.dart';
import 'package:app/data/datasources/models/product_model.dart';
import '../../../core/services/bonus_calculator.dart';
import '../../../core/services/cart_calculator.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/theme/app_theme.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;
  const EditOrderScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late List<EditableOrderItem> _items;
  late double _totalPrice;
  bool _isLoading = false;
  Map<String, ProductModel> _products = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      for (var item in widget.order.items) {
        if (!_products.containsKey(item.productId)) {
          final companyId = widget.order.companyId;
          await productProvider.loadProducts(companyId);
          final product = productProvider.products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => throw Exception('Product not found'),
          );
          _products[item.productId] = product;
        }
      }
      
      _initItems();
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initItems() {
    _items = widget.order.items.map((item) {
      final product = _products[item.productId];
      return EditableOrderItem(
        orderItem: item,
        product: product,
      );
    }).toList();
    _recalculateTotal();
  }

  void _recalculateTotal() {
    _totalPrice = _items.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    for (var item in _items) {
      item.recalculateBonus();
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      _items[index].quantity = newQuantity;
      _items[index].recalculateBonus();
      _recalculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _recalculateTotal();
    });
  }

  void _changeUnit(int index, String newUnit) {
    setState(() {
      final item = _items[index];
      if (item.unit == newUnit) return;
      
      if (item.piecesPerCarton == null || item.piecesPerCarton! <= 0) {
        SnackBarService.showWarning('لا يمكن تغيير الوحدة لهذا المنتج');
        return;
      }
      
      // ✅ استخدام CartCalculator للحسابات
      final newQuantity = CartCalculator.calculateQuantityAfterUnitChange(
        currentQuantity: item.quantity,
        currentUnit: item.unit,
        newUnit: newUnit,
        piecesPerCarton: item.piecesPerCarton!,
      );
      
      final newPricePerUnit = CartCalculator.calculatePriceAfterUnitChange(
        currentPrice: item.pricePerUnit,
        currentUnit: item.unit,
        newUnit: newUnit,
        piecesPerCarton: item.piecesPerCarton!,
      );
      
      if (newQuantity < 1) return;
      
      item.quantity = newQuantity;
      item.unit = newUnit;
      item.pricePerUnit = newPricePerUnit;
      
      // إعادة حساب الكمية بالباكيتات
      item.quantityInPieces = newUnit == 'carton' 
          ? newQuantity * item.piecesPerCarton! 
          : newQuantity;
      
      item.recalculateBonus();
      _recalculateTotal();
    });
  }

  Future<void> _saveChanges() async {
    if (widget.order.status != 'pending') {
      SnackBarService.showError('لا يمكن تعديل طلب تمت معالجته بالفعل');
      Navigator.pop(context);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      final newItems = _items.map((item) => OrderItem(
        productId: item.productId,
        productName: item.productName,
        scientificName: item.scientificName,
        quantity: item.quantity,
        quantityInPieces: item.quantityInPieces,
        unit: item.unit,
        piecesPerCarton: item.piecesPerCarton,
        price: item.pricePerUnit,
        bonusReceived: item.bonusReceived,
        totalPrice: item.totalPrice,
      )).toList();
      
      await orderProvider.updateOrderItems(widget.order.id, newItems, _totalPrice);
      
      SnackBarService.showSuccess('تم تعديل الطلب بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      SnackBarService.showError('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return  Scaffold(
        appBar: AppBar(title:const Text('تعديل الطلب'), centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:  Text('تعديل الطلب'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('لا توجد منتجات في الطلب'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'السعر: ${item.pricePerUnit.toStringAsFixed(2)} ${widget.order.currencySymbol} / ${item.unit == 'carton' ? 'كرتون' : 'باكيت'}',
                        ),
                        
                        if (item.bonusReceived > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🎁 بونص: +${item.bonusReceived} حبة مجانية',
                              style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                            ),
                          ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            const Text('الوحدة:'),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: item.unit,
                              items: const [
                                DropdownMenuItem(value: 'piece', child: Text('باكيت')),
                                DropdownMenuItem(value: 'carton', child: Text('كرتون')),
                              ],
                              onChanged: (newUnit) {
                                if (newUnit != null && newUnit != item.unit) {
                                  _changeUnit(index, newUnit);
                                }
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  _updateQuantity(index, item.quantity - 1);
                                }
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.quantity.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () => _updateQuantity(index, item.quantity + 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الإجمالي: ${item.totalPrice.toStringAsFixed(2)} ${widget.order.currencySymbol}'),
                            Text('${item.quantityInPieces} باكيت', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.primaryColor.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('الإجمالي الكلي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              '${_totalPrice.toStringAsFixed(2)} ${widget.order.currencySymbol}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== نموذج مساعد لتتبع العنصر القابل للتعديل ==========
class EditableOrderItem {
  final String productId;
  final String productName;
  final String scientificName;
  final ProductModel? product;
  
  int quantity;
  String unit;
  final int? piecesPerCarton;
  double pricePerUnit;
  int bonusReceived;
  int quantityInPieces;
  
  // تخزين الأسعار الأصلية للتحويل
  final double pricePerPiece;
  final double pricePerCarton;
  
  EditableOrderItem({
    required OrderItem orderItem,
    this.product,
  }) : productId = orderItem.productId,
       productName = orderItem.productName,
       scientificName = orderItem.scientificName,
       quantity = orderItem.quantity,
       unit = orderItem.unit,
       piecesPerCarton = orderItem.piecesPerCarton,
       pricePerUnit = orderItem.price,
       bonusReceived = orderItem.bonusReceived ?? 0,
       quantityInPieces = orderItem.quantityInPieces,
       pricePerPiece = orderItem.unit == 'piece' 
           ? orderItem.price 
           : (orderItem.price / (orderItem.piecesPerCarton ?? 1)),
       pricePerCarton = orderItem.unit == 'carton' 
           ? orderItem.price 
           : (orderItem.price * (orderItem.piecesPerCarton ?? 1));
  
  double get totalPrice => pricePerUnit * quantity;
  
  void recalculateBonus() {
    if (product == null) return;
    
    final bonusPercentage = BonusCalculator.getProductBonusPercentage(product!, true);
    
    if (bonusPercentage > 0) {
      bonusReceived = (quantityInPieces * bonusPercentage / 100).floor();
    } else {
      bonusReceived = 0;
    }
  }
}