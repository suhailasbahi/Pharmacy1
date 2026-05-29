// lib/modules/pharmacy/screens/offers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/datasources/models/product_model.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/widgets/enhanced_product_card.dart';
import '../../../core/utils/product_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<ProductModel> _offerProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferProducts();
  }

  Future<void> _loadOfferProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final regionId = authService.currentRegionId ?? 'sanaa';
      
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
      
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
      
      // ✅ استخدام ProductHelper للفلترة
      final offers = allProducts.where((product) {
        // عرض عام على المنتج
        if (ProductHelper.hasGlobalOffer(product)) {
          return true;
        }
        // عرض خاص بمنطقة معينة
        if (ProductHelper.hasOffer(product, regionId)) {
          return true;
        }
        return false;
      }).toList();
      
      setState(() {
        _offerProducts = offers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading offer products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadOfferProducts();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';
    final cartProvider = Provider.of<CartProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(title: Text('العروض الخاصة'), centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('العروض الخاصة'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _offerProducts.isEmpty
            ? const EmptyWidget(
                title: 'لا توجد عروض حالياً',
                subtitle: 'ترقبوا عروضنا القادمة',
                icon: Icons.local_offer,
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _offerProducts.length,
                itemBuilder: (context, index) {
                  final product = _offerProducts[index];
                  final isInCart = cartProvider.isInCart(product.id);
                  
                  return EnhancedProductCard(
                    product: product,
                    regionId: regionId,
                    isInCart: isInCart,
                    showAddToCart: true,
                    onAddToCart: () {
                      final cartItem = CartItem.fromProduct(product, regionId);
                      cartProvider.addToCart(cartItem, isCashOrder: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إضافة ${product.name} إلى السلة'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}