// lib/core/widgets/enhanced_product_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'cached_image.dart';
import '../../core/extensions/num_extensions.dart';
import '../../core/utils/category_utils.dart';
import '../../data/datasources/models/product_model.dart';

class EnhancedProductCard extends StatelessWidget {
  final ProductModel product;
  final String regionId;
  final VoidCallback? onAddToCart;
  final bool isInCart;
  final VoidCallback? onTap;
  final bool showCompanyName;
  final bool showBonus;
  
  const EnhancedProductCard({
    Key? key,
    required this.product,
    required this.regionId,
    this.onAddToCart,
    this.isInCart = false,
    this.onTap,
    this.showCompanyName = true,
    this.showBonus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasOffer = product.hasOfferForRegion(regionId);
    final displayPrice = product.getFinalPriceForRegion(regionId);
    final originalPrice = product.getOriginalPriceForRegion(regionId);
    final discount = hasOffer ? ((originalPrice - displayPrice) / originalPrice * 100).toInt() : 0;
    final currencySymbol = product.getCurrencyForRegion(regionId) == 'saudi' ? 'ر.س' : 'ر.ي';
    final category = CategoryUtils.getCategoryFromName(product.name);
    final maxBonus = (product.bonusCash?.percentage ?? 0) > (product.bonusCredit?.percentage ?? 0)
        ? (product.bonusCash?.percentage ?? 0)
        : (product.bonusCredit?.percentage ?? 0);
    final isLowStock = product.stockQuantity > 0 && product.stockQuantity < 10;
    final isOutOfStock = product.stockQuantity == 0;
    
    return GestureDetector(
      onTap: onTap ?? () => _navigateToDetails(context),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedImage(
                    imageUrl: product.imageUrl,
                    filePath: product.imageUrl,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                // علامة العرض
                if (hasOffer)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // علامة الكمية المتبقية
                if (isLowStock && !isOutOfStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'متبقي ${product.stockQuantity}',
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
                // علامة غير متوفر
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(
                        child: Text(
                          'غير متوفر',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // معلومات المنتج
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المنتج
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // التركيز
                  Text(
                    product.concentration,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // السعر
                  Row(
                    children: [
                      if (hasOffer) ...[
                        Text(
                          displayPrice.formatPrice(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          originalPrice.formatPrice(),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        Text(
                          displayPrice.formatPrice(),
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      Text(
                        ' $currencySymbol',
                        style: TextStyle(
                          color: hasOffer ? Colors.red : Colors.teal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  // اسم الشركة
                  if (showCompanyName && product.companyName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.companyName,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // البونص
                  if (showBonus && maxBonus > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'بونص يصل إلى ${maxBonus.toInt()}%',
                        style: TextStyle(fontSize: 9, color: Colors.amber.shade800),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // زر الإضافة
                  if (onAddToCart != null && !isOutOfStock)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? Colors.grey : Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          isInCart ? '✓ في السلة' : 'أضف إلى السلة',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(product: product, regionId: regionId),
      ),
    );
  }
}