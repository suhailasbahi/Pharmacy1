// lib/modules/pharmacy/screens/product_details_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/datasources/models/product_model.dart';
import '../../../data/datasources/models/cart_item.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/product_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_image.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;
  final String regionId;

  const ProductDetailsScreen({Key? key, required this.product, required this.regionId}) : super(key: key);

  Future<List<ProductModel>> _getSimilarProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('scientificName', isEqualTo: product.scientificName)
          .where('isActive', isEqualTo: true)
          .get();
      
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
      
      return allProducts.where((p) => p.id != product.id).toList();
    } catch (e) {
      debugPrint('Error loading similar products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final effectiveCompanyName = (authService.currentCompanyId == product.companyId && authService.currentCompanyName != null)
        ? authService.currentCompanyName
        : product.companyName;

    final isPharmacy = authService.currentUserType == 'pharmacy';
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(product.id);
    
    // ✅ استخدام ProductHelper للحسابات
    final hasOffer = ProductHelper.hasOffer(product, regionId);
    final priceText = ProductHelper.getPriceWithOfferText(product, regionId);
    final currencySymbol = ProductHelper.getCurrencySymbol(product, regionId);
    final discount = ProductHelper.getDiscountPercentage(product, regionId);
    
    final maxBonus = (product.bonusCash?.percentage ?? 0) > (product.bonusCredit?.percentage ?? 0)
        ? (product.bonusCash?.percentage ?? 0)
        : (product.bonusCredit?.percentage ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Container(
              height: 250,
              width: double.infinity,
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Stack(
                children: [
                  Center(
                    child: CachedImage(
                      imageUrl: product.imageUrl,
                      filePath: product.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (hasOffer)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المنتج
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.scientificName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.concentration,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  
                  // السعر
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: hasOffer ? Colors.red.shade50 : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('السعر:', style: TextStyle(fontSize: 18)),
                        if (hasOffer)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                priceText['current']!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                priceText['original']!,
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            priceText['current']!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // معلومات الكرتون
                  if (product.piecesPerCarton > 0 && product.defaultUnit == 'carton')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'الكرتون الواحد يحتوي على ${product.piecesPerCarton} باكيت\nيمكنك شراء الباكيت بسعر ${product.pricePerPiece} $currencySymbol',
                              style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // البونص
                  if (maxBonus > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.percent, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'بونص يصل إلى $maxBonus% على الكمية',
                              style: TextStyle(color: Colors.amber.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // معلومات إضافية
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow('شركة الأدوية:', product.companyName),
                          _buildInfoRow('تاريخ الصلاحية:', _formatDate(product.expiryDate)),
                          _buildInfoRow('يحتاج تبريد:', product.requiresCooling ? 'نعم' : 'لا'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // زر الإضافة للسلة
                  if (isPharmacy && product.stockQuantity > 0)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isInCart) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} موجود بالفعل في السلة')),
                            );
                          } else {
                            final cartItem = CartItem.fromProduct(product, regionId, overriddenCompanyName: effectiveCompanyName);
                            cartProvider.addToCart(cartItem, isCashOrder: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم إضافة ${product.name} إلى السلة'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? Colors.grey : AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isInCart ? 'المنتج موجود في السلة' : 'أضف إلى السلة',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  
                  if (isPharmacy && product.stockQuantity == 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'المنتج غير متوفر حالياً',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // منتجات مشابهة
                  FutureBuilder<List<ProductModel>>(
                    future: _getSimilarProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      
                      final similar = snapshot.data ?? [];
                      if (similar.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'منتجات مشابهة (نفس الاسم العلمي)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: similar.length,
                              itemBuilder: (ctx, idx) {
                                final p = similar[idx];
                                final pHasOffer = ProductHelper.hasOffer(p, regionId);
                                final pPriceText = ProductHelper.getPriceWithOfferText(p, regionId);
                                
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsScreen(product: p, regionId: regionId),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Container(
                                      width: 140,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CachedImage(
                                            imageUrl: p.imageUrl,
                                            filePath: p.imageUrl,
                                            height: 80,
                                            width: double.infinity,
                                            borderRadius: 8,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            p.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (pHasOffer)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pPriceText['current']!,
                                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                                Text(
                                                  pPriceText['original']!,
                                                  style: const TextStyle(
                                                    decoration: TextDecoration.lineThrough,
                                                    color: Colors.grey,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              pPriceText['current']!,
                                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}