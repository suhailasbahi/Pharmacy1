// lib/data/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../datasources/models/cart_item.dart';
import '../../core/services/bonus_calculator.dart';
import '../../core/services/cart_calculator.dart';
import '../../core/services/currency_converter.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  // ==================== دوال الحسابات الأساسية (جديدة) ====================
  
  /// إجمالي السلة
  double get totalPrice => CartCalculator.calculateTotal(_items);
  
  /// إجمالي الكمية
  int get totalQuantity => CartCalculator.calculateTotalQuantity(_items);
  
  /// إجمالي البونص
  int get totalBonus => CartCalculator.calculateTotalBonus(_items);
  
  /// عدد العناصر في السلة
  int get itemCount => CartCalculator.calculateItemCount(_items);
  
  /// إجمالي القطع (باكيتات)
  int get totalPieces => CartCalculator.calculateTotalPieces(_items);
  
  /// تجميع العناصر حسب الشركة والعملة
  Map<String, List<CartItem>> get itemsByCompanyAndCurrency {
    return CartCalculator.groupByCompanyAndCurrency(_items);
  }
  
  /// الحصول على إجمالي شركة معينة
  double getCompanyTotal(String companyId, String currency) {
    final key = '${companyId}_${currency}';
    final companyItems = itemsByCompanyAndCurrency[key] ?? [];
    return CartCalculator.calculateTotal(companyItems);
  }
  
  /// الحصول على إجماليات كل عملة
  Map<String, double> get currencyTotals {
    return CartCalculator.calculateCurrencyTotals(_items);
  }
  
  /// نص ملخص السلة
  String get summaryText => CartCalculator.getSummaryText(_items);
  
  /// الحصول على نص الإجمالي الكلي (مع العملات)
  String getTotalText() {
    final totals = currencyTotals;
    return totals.entries
        .map((e) => '${e.value.toStringAsFixed(2)} ${CurrencyConverter.getSymbol(e.key)}')
        .join(' + ');
  }
  
  /// التحقق من وجود منتج في السلة
  bool isInCart(String productId) => _items.any((item) => item.id == productId);

  // ==================== دوال مساعدة داخلية ====================
  
  void _applyBonus(CartItem item, bool isCashOrder) {
    item.bonus = BonusCalculator.calculateItemBonus(
      item: item,
      isCashOrder: isCashOrder,
    );
  }

  void updateBonusesForCompany(String companyId, bool isCashOrder) {
    BonusCalculator.updateCompanyBonuses(
      items: _items,
      companyId: companyId,
      isCashOrder: isCashOrder,
    );
    notifyListeners();
  }

  int _getMinAllowedQuantity(CartItem item) {
    return CartCalculator.getMinAllowedQuantity(item);
  }

  // ==================== دوال تعديل السلة ====================
  
  void addToCart(CartItem item, {bool isCashOrder = true}) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
      _applyBonus(_items[existingIndex], isCashOrder);
    } else {
      int initialQty = item.quantity;
      int minQty = _getMinAllowedQuantity(item);
      if (initialQty < minQty) initialQty = minQty;
      item.quantity = initialQty;
      _items.add(item);
      _applyBonus(item, isCashOrder);
    }
    notifyListeners();
  }

  void increaseQuantity(String productId, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index != -1) {
      _items[index].quantity++;
      _applyBonus(_items[index], isCashOrder);
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index != -1) {
      final item = _items[index];
      final minAllowed = _getMinAllowedQuantity(item);
      if (item.quantity > minAllowed) {
        item.quantity--;
        _applyBonus(item, isCashOrder);
        notifyListeners();
      }
    }
  }

  void updateQuantity(String productId, int newQuantity, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index != -1) {
      final item = _items[index];
      final minAllowed = _getMinAllowedQuantity(item);
      int finalQty = newQuantity;
      if (finalQty < minAllowed) finalQty = minAllowed;
      if (finalQty > 0) {
        _items[index].quantity = finalQty;
        _applyBonus(_items[index], isCashOrder);
        notifyListeners();
      }
    }
  }

  void changeUnit(String productId, String newUnit, BuildContext context, {bool isCashOrder = true}) {
    final index = _items.indexWhere((item) => item.id == productId);
    if (index == -1) return;
    
    final item = _items[index];
    if (item.unit == newUnit) return;
    
    if (item.piecesPerCarton <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا المنتج لا يدعم الشراء بالكرتون'), backgroundColor: Colors.orange),
      );
      return;
    }

    final newQuantity = CartCalculator.convertQuantityForUnitChange(item, newUnit);
    
    if (newQuantity > 0) {
      item.quantity = newQuantity;
      item.unit = newUnit;
      final minAllowed = _getMinAllowedQuantity(item);
      if (item.quantity < minAllowed) item.quantity = minAllowed;
      _applyBonus(item, isCashOrder);
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}