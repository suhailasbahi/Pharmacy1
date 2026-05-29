import 'product_model.dart';

class CartItem {
  final String id;
  final String companyId;
  final String companyName;
  final String name;
  final String scientificName;
  final String concentration;
  final bool requiresCooling;
  int quantity;
  int bonus;
  final String regionId;
  final String currency;  // 'yemen', 'saudi', 'dollar'

  String unit;
  final int piecesPerCarton;
  final double pricePerPiece;
  final double pricePerCarton;
  final int minOrderQuantity;

  final double? bonusCashPercentage;
  final double? bonusCreditPercentage;

  CartItem({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.scientificName,
    required this.concentration,
    required this.requiresCooling,
    this.quantity = 1,
    this.bonus = 0,
    required this.regionId,
    required this.currency,
    required this.unit,
    required this.piecesPerCarton,
    required this.pricePerPiece,
    required this.pricePerCarton,
    required this.minOrderQuantity,
    this.bonusCashPercentage,
    this.bonusCreditPercentage,
  });

  factory CartItem.fromProduct(ProductModel product, String regionId, {bool isCashOrder = true, String? overriddenCompanyName}) {
    final pricing = product.getPricingForRegion(regionId);
    double regionPrice = pricing?.getFinalPrice() ?? 0;
    
    double effectivePricePerPiece;
    double effectivePricePerCarton;
    
    if (product.defaultUnit == 'piece') {
      effectivePricePerPiece = regionPrice;
      effectivePricePerCarton = regionPrice * product.piecesPerCarton;
    } else {
      effectivePricePerCarton = regionPrice;
      effectivePricePerPiece = regionPrice / product.piecesPerCarton;
    }
    
    if (product.hasOffer && product.offerPrice != null) {
      final offerPriceValue = product.offerPrice!;
      if (product.defaultUnit == 'piece') {
        effectivePricePerPiece = offerPriceValue;
        effectivePricePerCarton = offerPriceValue * product.piecesPerCarton;
      } else {
        effectivePricePerCarton = offerPriceValue;
        effectivePricePerPiece = offerPriceValue / product.piecesPerCarton;
      }
    }
    
    return CartItem(
      id: product.id,
      companyId: product.companyId,
      companyName: overriddenCompanyName ?? product.companyName,
      name: product.name,
      scientificName: product.scientificName,
      concentration: product.concentration,
      requiresCooling: product.requiresCooling,
      regionId: regionId,
      currency: product.getCurrencyForRegion(regionId),
      unit: product.defaultUnit,
      piecesPerCarton: product.piecesPerCarton,
      pricePerPiece: effectivePricePerPiece,
      pricePerCarton: effectivePricePerCarton,
      minOrderQuantity: product.minOrderQuantity,
      bonusCashPercentage: product.bonusCash?.percentage,
      bonusCreditPercentage: product.bonusCredit?.percentage,
    );
  }

  String get currencySymbol {
    switch (currency) {
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  double get unitPrice => unit == 'piece' ? pricePerPiece : pricePerCarton;
  double get totalPrice => unitPrice * quantity;
  int get totalPieces => unit == 'piece' ? quantity : quantity * piecesPerCarton;

  double getBonusPercentage(bool isCashOrder) {
    if (isCashOrder && bonusCashPercentage != null) return bonusCashPercentage!;
    if (!isCashOrder && bonusCreditPercentage != null) return bonusCreditPercentage!;
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'name': name,
      'scientificName': scientificName,
      'concentration': concentration,
      'requiresCooling': requiresCooling,
      'quantity': quantity,
      'bonus': bonus,
      'regionId': regionId,
      'currency': currency,
      'unit': unit,
      'piecesPerCarton': piecesPerCarton,
      'pricePerPiece': pricePerPiece,
      'pricePerCarton': pricePerCarton,
      'minOrderQuantity': minOrderQuantity,
      'bonusCashPercentage': bonusCashPercentage,
      'bonusCreditPercentage': bonusCreditPercentage,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      concentration: map['concentration'] ?? '',
      requiresCooling: map['requiresCooling'] ?? false,
      quantity: map['quantity'] ?? 1,
      bonus: map['bonus'] ?? 0,
      regionId: map['regionId'] ?? '',
      currency: map['currency'] ?? 'yemen',
      unit: map['unit'] ?? 'piece',
      piecesPerCarton: map['piecesPerCarton'] ?? 1,
      pricePerPiece: (map['pricePerPiece'] ?? 0).toDouble(),
      pricePerCarton: (map['pricePerCarton'] ?? 0).toDouble(),
      minOrderQuantity: map['minOrderQuantity'] ?? 1,
      bonusCashPercentage: map['bonusCashPercentage']?.toDouble(),
      bonusCreditPercentage: map['bonusCreditPercentage']?.toDouble(),
    );
  }
}