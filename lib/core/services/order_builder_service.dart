import 'package:app/data/datasources/models/cart_item.dart';
import 'package:app/data/datasources/models/order_model.dart';

class OrderBuilderService {
  static OrderModel buildOrder({
    required List<CartItem> cartItems,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyCity,
    required String regionId,
    required String companyId,
    required String companyName,
    required String paymentType,
    required String paymentMethod,
    int? creditDays,
  }) {
    final orderItems = cartItems.map((item) {
      return OrderItem(
        productId: item.id,
        productName: item.name,
        scientificName: item.scientificName,
        quantity: item.quantity,
        quantityInPieces: item.totalPieces,
        unit: item.unit,
        piecesPerCarton: item.piecesPerCarton,
        price: item.unitPrice,
        bonusReceived: item.bonus,
        totalPrice: item.totalPrice,
      );
    }).toList();

    final totalPrice = cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    return OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pharmacyCity: pharmacyCity,
      regionId: regionId,
      companyId: companyId,
      companyName: companyName,
      items: orderItems,
      totalPrice: totalPrice,
      currency: cartItems.first.currency,
      status: 'pending',
      date: DateTime.now(),
      paymentType: paymentType,
      paymentMethod: paymentMethod,
      creditDays: creditDays,
    );
  }
}