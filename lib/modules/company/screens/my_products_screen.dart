// lib/modules/company/screens/my_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/datasources/models/product_model.dart';
import '../../../core/utils/product_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/services/debouncer.dart';
import 'edit_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer();
  
  String _searchQuery = '';
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final companyId = auth.currentCompanyId ?? 'comp_001';
      
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('companyId', isEqualTo: companyId)
          .get();
      
      _products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      SnackBarService.showError('حدث خطأ في تحميل المنتجات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debouncer.call(() {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
        await _loadProducts();
        SnackBarService.showSuccess('تم حذف المنتج بنجاح');
      } catch (e) {
        SnackBarService.showError('حدث خطأ: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    // ✅ استخدام ProductHelper للفلترة
    final filteredProducts = ProductHelper.filterCompanyProducts(_products, _searchQuery);

    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(title: Text('منتجاتي'), centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: filteredProducts.isEmpty
            ? const EmptyWidget(
                title: 'لا توجد منتجات',
                subtitle: 'أضف منتجاً جديداً باستخدام زر +',
                icon: Icons.inventory,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final samplePrice = ProductHelper.getSamplePrice(product);
                  final currencySymbol = ProductHelper.getSampleCurrencySymbol(product);
                  final stockColor = ProductHelper.getStockColor(product.stockQuantity);
                  final stockText = ProductHelper.getStockText(product.stockQuantity);
                  final bonusText = ProductHelper.getBonusDisplayText(product);
                  final hasGlobalOffer = ProductHelper.hasGlobalOffer(product);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // صورة مصغرة
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.medication, color: AppTheme.primaryColor, size: 30),
                          ),
                          const SizedBox(width: 12),
                          
                          // معلومات المنتج
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  product.concentration,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                
                                // السعر والمخزون
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$samplePrice $currencySymbol',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stockColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        stockText,
                                        style: TextStyle(fontSize: 12, color: stockColor),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // البونص
                                if (bonusText.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      bonusText,
                                      style: TextStyle(fontSize: 10, color: Colors.amber.shade800),
                                    ),
                                  ),
                                
                                // عرض عام
                                if (hasGlobalOffer)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'عرض: ${product.offerPrice} بدلاً من $samplePrice',
                                      style: const TextStyle(fontSize: 10, color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // أزرار التحكم
                          Column(
                            children: [
                              if (auth.canEditProduct)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProductScreen(
                                          product: product,
                                          agencyId: product.agencyId,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      await _loadProducts();
                                      SnackBarService.showSuccess('تم تحديث المنتج');
                                    }
                                  },
                                ),
                              if (auth.canDeleteProduct)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteProduct(product),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}