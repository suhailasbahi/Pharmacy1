// lib/core/widgets/quantity_selector.dart
import 'package:flutter/material.dart';

class QuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final int minQuantity;
  final int maxQuantity;
  final Function(int) onQuantityChanged;
  final bool showButtons;
  final double buttonSize;
  final double fontSize;
  final Color? primaryColor;
  
  const QuantitySelector({
    Key? key,
    this.initialQuantity = 1,
    this.minQuantity = 1,
    this.maxQuantity = 999,
    required this.onQuantityChanged,
    this.showButtons = true,
    this.buttonSize = 32,
    this.fontSize = 16,
    this.primaryColor,
  }) : super(key: key);

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity.clamp(widget.minQuantity, widget.maxQuantity);
  }

  void _increment() {
    if (_quantity < widget.maxQuantity) {
      setState(() => _quantity++);
      widget.onQuantityChanged(_quantity);
    }
  }

  void _decrement() {
    if (_quantity > widget.minQuantity) {
      setState(() => _quantity--);
      widget.onQuantityChanged(_quantity);
    }
  }

  void _onQuantitySubmitted(String value) {
    final int? newQuantity = int.tryParse(value);
    if (newQuantity != null) {
      _quantity = newQuantity.clamp(widget.minQuantity, widget.maxQuantity);
      setState(() {});
      widget.onQuantityChanged(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    
    if (!widget.showButtons) {
      return _buildSimpleSelector(primaryColor);
    }
    
    return _buildButtonSelector(primaryColor);
  }

  Widget _buildButtonSelector(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر ناقص
          InkWell(
            onTap: _decrement,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: widget.buttonSize,
              height: widget.buttonSize,
              decoration: BoxDecoration(
                color: _quantity <= widget.minQuantity ? Colors.grey.shade100 : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.remove,
                color: _quantity <= widget.minQuantity ? Colors.grey : Colors.red,
                size: 20,
              ),
            ),
          ),
          
          // عرض الكمية
          SizedBox(
            width: 50,
            child: TextField(
              controller: TextEditingController(text: _quantity.toString()),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: _onQuantitySubmitted,
            ),
          ),
          
          // زر زائد
          InkWell(
            onTap: _increment,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: widget.buttonSize,
              height: widget.buttonSize,
              decoration: BoxDecoration(
                color: _quantity >= widget.maxQuantity ? Colors.grey.shade100 : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                color: _quantity >= widget.maxQuantity ? Colors.grey : Colors.green,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSelector(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('الكمية:'),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: _quantity.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onFieldSubmitted: _onQuantitySubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

/// منتقي الكمية للكرتون/باكيت
class UnitQuantitySelector extends StatefulWidget {
  final int quantity;
  final String unit;
  final int piecesPerCarton;
  final Function(int quantity, String unit) onChanged;
  final int minQuantity;
  final int maxQuantity;
  
  const UnitQuantitySelector({
    Key? key,
    required this.quantity,
    required this.unit,
    required this.piecesPerCarton,
    required this.onChanged,
    this.minQuantity = 1,
    this.maxQuantity = 999,
  }) : super(key: key);

  @override
  State<UnitQuantitySelector> createState() => _UnitQuantitySelectorState();
}

class _UnitQuantitySelectorState extends State<UnitQuantitySelector> {
  late int _quantity;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
    _unit = widget.unit;
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity < widget.minQuantity) newQuantity = widget.minQuantity;
    if (newQuantity > widget.maxQuantity) newQuantity = widget.maxQuantity;
    setState(() => _quantity = newQuantity);
    widget.onChanged(_quantity, _unit);
  }

  void _toggleUnit() {
    final newUnit = _unit == 'piece' ? 'carton' : 'piece';
    int newQuantity;
    
    if (_unit == 'piece' && newUnit == 'carton') {
      newQuantity = (_quantity / widget.piecesPerCarton).ceil();
    } else {
      newQuantity = _quantity * widget.piecesPerCarton;
    }
    
    setState(() {
      _unit = newUnit;
      _quantity = newQuantity;
    });
    widget.onChanged(_quantity, _unit);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // منتقي الوحدة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _unit,
              items: const [
                DropdownMenuItem(value: 'piece', child: Text('باكيت')),
                DropdownMenuItem(value: 'carton', child: Text('كرتون')),
              ],
              onChanged: (value) {
                if (value != null && value != _unit) {
                  _toggleUnit();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // منتقي الكمية
        Expanded(
          child: QuantitySelector(
            initialQuantity: _quantity,
            minQuantity: widget.minQuantity,
            maxQuantity: widget.maxQuantity,
            onQuantityChanged: _updateQuantity,
          ),
        ),
      ],
    );
  }
}