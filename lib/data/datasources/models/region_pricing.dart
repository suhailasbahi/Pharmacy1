class RegionPricing {
  final String regionId;
  final String regionName;
  
  // السعر (بالعملة المختارة)
  final double price;
  
  // العملة: 'yemen', 'saudi', 'dollar'
  final String currency;
  
  final bool hasOffer;
  final double? offerPrice;

  RegionPricing({
    required this.regionId,
    required this.regionName,
    required this.price,
    required this.currency,
    this.hasOffer = false,
    this.offerPrice,
  });

  double getFinalPrice() {
    if (hasOffer && offerPrice != null) return offerPrice!;
    return price;
  }

  double getBasePrice() {
    return price;
  }

  String get currencySymbol {
    switch (currency) {
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  String get currencyName {
    switch (currency) {
      case 'saudi': return 'ريال سعودي';
      case 'dollar': return 'دولار أمريكي';
      default: return 'ريال يمني';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'regionId': regionId,
      'regionName': regionName,
      'price': price,
      'currency': currency,
      'hasOffer': hasOffer,
      'offerPrice': offerPrice,
    };
  }

  factory RegionPricing.fromMap(Map<String, dynamic> map) {
    return RegionPricing(
      regionId: map['regionId'] ?? '',
      regionName: map['regionName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: _sanitizeCurrency(map['currency']),
      hasOffer: map['hasOffer'] ?? false,
      offerPrice: map['offerPrice']?.toDouble(),
    );
  }

  static String _sanitizeCurrency(dynamic currency) {
    if (currency == 'saudi') return 'saudi';
    if (currency == 'dollar') return 'dollar';
    return 'yemen';
  }
}